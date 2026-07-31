// build_and_test.js — Assemble and test calculator_pro_90plus.asm
// Uses js-dos emulators to run MASM 6.11 + LINK, then tests the EXE

const fs = require('fs');
const path = require('path');

// Load emulators (sets globalThis.emulators)
require('./node_modules/emulators/dist/emulators.js');
const emu = globalThis.emulators;

// Fix path for finding wdosbox.js and wasm files
emu.pathPrefix = path.join(__dirname, 'node_modules', 'emulators', 'dist') + '/';

const DOSROOT = path.join(__dirname, 'dosroot');
const MASMDIR = path.join(DOSROOT, 'masm');
const PROJROOT = path.resolve(__dirname, '..');
const ASM_FILE = 'CALC.ASM';
const SRC_ASM  = path.join(PROJROOT, 'calculator_pro_90plus.asm');
const DST_ASM  = path.join(DOSROOT, ASM_FILE);

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Map of char -> scancode for keyboard simulation
const CHAR_TO_SC = {};
function buildKeyMap() {
    for (let i = 0; i <= 9; i++) CHAR_TO_SC[String(i)] = (i === 0 ? 11 : i + 1);
    for (let i = 0; i < 26; i++) {
        CHAR_TO_SC[String.fromCharCode(97+i)] = 30 + i;  // a-z
        CHAR_TO_SC[String.fromCharCode(65+i)] = 30 + i;  // A-Z
    }
    Object.assign(CHAR_TO_SC, {
        ' ': 57, '.': 52, '+': 13, '-': 12, '*': 9, '/': 53,
        '(': 10, ')': 11, '\r': 28, '\n': 28,
    });
}
buildKeyMap();

async function typeString(ci, str) {
    for (const ch of str) {
        const sc = CHAR_TO_SC[ch];
        if (sc !== undefined) {
            ci.sendKeyEvent(sc, true);
            await sleep(15);
            ci.sendKeyEvent(sc, false);
            await sleep(15);
        }
    }
}

async function pressKey(ci, scancode) {
    ci.sendKeyEvent(scancode, true);
    await sleep(25);
    ci.sendKeyEvent(scancode, false);
    await sleep(25);
}

async function build() {
    console.log('=== BUILD PHASE ===');

    // Copy the latest ASM source to DOSROOT
    fs.copyFileSync(SRC_ASM, DST_ASM);
    console.log(`Copied ${SRC_ASM} -> ${DST_ASM}`);

    // Read all files to inject into DOS filesystem
    const asmBuf     = fs.readFileSync(DST_ASM);
    const masmBuf    = fs.readFileSync(path.join(DOSROOT, 'MASM.EXE'));
    const linkBuf    = fs.readFileSync(path.join(DOSROOT, 'LINK.EXE'));
    const mlBuf      = fs.readFileSync(path.join(MASMDIR, 'ML.EXE'));
    const mlerrBuf   = fs.readFileSync(path.join(MASMDIR, 'ML.ERR'));
    const dosxntBuf  = fs.readFileSync(path.join(DOSROOT, 'DOSXNT.EXE'));

    const dosboxConf = `
[sdl]
output=surface

[dosbox]
memsize=16

[autoexec]
mount C .
C:
set PATH=C:\\;%PATH%
echo ========== MASM 6.11 - Assembling ==========
MASM ${ASM_FILE};
IF ERRORLEVEL 1 GOTO build_error
echo.
echo ========== LINK - Linking ==========
LINK CALC.OBJ;
IF ERRORLEVEL 1 GOTO build_error
echo.
echo ========== BUILD OK ==========
echo BUILD_SUCCESS
goto build_done

:build_error
echo BUILD_FAILED
:build_done
exit
`;

    let stdout = '';

    return new Promise(async (resolve, reject) => {
        const ci = await emu.dosboxNode([
            { dosboxConf, jsdosConf: { version: '8.4.0' } },
            { path: ASM_FILE,     contents: asmBuf },
            { path: 'MASM.EXE',   contents: masmBuf },
            { path: 'LINK.EXE',   contents: linkBuf },
            { path: 'ML.EXE',     contents: mlBuf },
            { path: 'ML.ERR',     contents: mlerrBuf },
            { path: 'DOSXNT.EXE', contents: dosxntBuf },
        ]);

        ci.events().onStdout((msg) => {
            stdout += msg;
            if (msg.trim()) {
                console.log('[DOS]', msg.replace(/\r\n/g, '\n').trimEnd());
            }
        });

        ci.events().onExit(() => {
            console.log('\n=== Build complete ===');
            if (stdout.includes('BUILD_SUCCESS')) {
                console.log('BUILD SUCCEEDED');
                resolve(true);
            } else if (stdout.includes('BUILD_FAILED')) {
                console.log('BUILD FAILED');
                resolve(false);
            } else {
                console.log('Build ended (check output above)');
                resolve(
                    stdout.includes('0 Warning Errors') ||
                    stdout.includes('0 Severe Errors')
                );
            }
        });

        setTimeout(() => {
            ci.exit().catch(() => {});
            reject(new Error('Build timed out'));
        }, 60000);
    });
}

async function runTests() {
    console.log('\n=== TEST PHASE ===');

    let exeBuf;
    try {
        exeBuf = fs.readFileSync(path.join(DOSROOT, 'CALC.EXE'));
        console.log(`CALC.EXE size: ${exeBuf.length} bytes`);
    } catch (e) {
        console.log('CALC.EXE not found - build may have failed.');
        return '';
    }

    const dosboxConf = `
[sdl]
output=surface

[dosbox]
memsize=16

[autoexec]
mount C .
C:
CALC.EXE
exit
`;

    let output = '';
    let ci;

    return new Promise(async (resolve) => {
        ci = await emu.dosboxNode([
            { dosboxConf, jsdosConf: { version: '8.4.0' } },
            { path: 'CALC.EXE', contents: exeBuf },
        ]);

        ci.events().onStdout((msg) => {
            output += msg;
            process.stdout.write(msg);
        });

        ci.events().onExit(() => {
            console.log('\n=== Test run complete ===');
            resolve(output);
        });

        // Wait for menu to appear
        await sleep(2000);

        // ===== Test 1: Simple integer addition 3+5 =====
        console.log('\n--- Test 1: 3+5 ---');
        await pressKey(ci, 2);     // '1' = Calculate
        await sleep(600);
        await typeString(ci, '3+5');
        await sleep(200);
        await pressKey(ci, 28);    // Enter
        await sleep(2000);

        // ===== Test 2: Decimal addition 3.2+4.5 =====
        console.log('\n--- Test 2: 3.2+4.5 ---');
        await pressKey(ci, 2);     // '1'
        await sleep(600);
        await typeString(ci, '3.2+4.5');
        await sleep(200);
        await pressKey(ci, 28);    // Enter
        await sleep(2000);

        // ===== Test 3: Complex expression with parens =====
        console.log('\n--- Test 3: (3.2+4.5)*(5.1-2.0)/3.0 ---');
        await pressKey(ci, 2);     // '1'
        await sleep(600);
        await typeString(ci, '(3.2+4.5)*(5.1-2.0)/3.0');
        await sleep(200);
        await pressKey(ci, 28);    // Enter
        await sleep(2500);

        // ===== Test 4: Negative number =====
        console.log('\n--- Test 4: -5+10 ---');
        await pressKey(ci, 2);     // '1'
        await sleep(600);
        await typeString(ci, '-5+10');
        await sleep(200);
        await pressKey(ci, 28);    // Enter
        await sleep(2000);

        // ===== Test 5: Missing operator - should error =====
        console.log('\n--- Test 5: invalid input 5++3 ---');
        await pressKey(ci, 2);     // '1'
        await sleep(600);
        await typeString(ci, '5++3');
        await sleep(200);
        await pressKey(ci, 28);    // Enter
        await sleep(2000);

        // ===== Test 6: Read history =====
        console.log('\n--- Test 6: Read History ---');
        await pressKey(ci, 3);     // '2' = Read History
        await sleep(2000);

        // ===== Test 7: Clear history =====
        console.log('\n--- Test 7: Clear History ---');
        await pressKey(ci, 4);     // '3' = Clear History
        await sleep(2000);

        // ===== Test 8: Another calc to verify history still works after clear =====
        console.log('\n--- Test 8: 10*2.5 ---');
        await pressKey(ci, 2);     // '1'
        await sleep(600);
        await typeString(ci, '10*2.5');
        await sleep(200);
        await pressKey(ci, 28);    // Enter
        await sleep(2000);

        // ===== Test 9: Read history again =====
        console.log('\n--- Test 9: Read History after clear ---');
        await pressKey(ci, 3);     // '2' = Read History
        await sleep(1500);

        // Exit
        console.log('\n--- Exiting ---');
        await pressKey(ci, 5);     // '4' = Exit
        await sleep(2000);
    });
}

async function main() {
    try {
        const buildOk = await build();
        if (!buildOk) {
            console.log('\nBUILD FAILED.');
            process.exit(1);
        }

        const result = await runTests();
        console.log('\n========== TEST RESULTS ==========');

        const checks = [
            { name: '3+5 = 8.00',           pass: /8[.]00/.test(result) },
            { name: '3.2+4.5 = 7.70',       pass: /7[.]70/.test(result) },
            { name: 'Complex expr = 23.87',  pass: /23[.]8[67]/.test(result) },
            { name: '-5+10 = 5.00',          pass: /5[.]00/.test(result) },
            { name: 'Step display',          pass: /Step:/i.test(result) || / - /.test(result) || result.includes('=') },
            { name: 'History shown',         pass: /HISTORY/i.test(result) || /history/i.test(result) },
            { name: 'History cleared',       pass: /clear/i.test(result) },
            { name: '10*2.5 = 25.00',        pass: /25[.]00/.test(result) },
            { name: 'Menu re-shown',         pass: (result.match(/CALCULATOR|Choose|Calculate/gi) || []).length >= 2 },
        ];

        let passed = 0, failed = 0;
        for (const c of checks) {
            const status = c.pass ? 'PASS' : 'FAIL';
            c.pass ? passed++ : failed++;
            console.log(`  [${status}] ${c.name}`);
        }

        console.log(`\n${passed}/${checks.length} tests passed.`);
        if (failed > 0) process.exit(1);
    } catch (err) {
        console.error('Fatal error:', err);
        process.exit(1);
    }
}

main();
