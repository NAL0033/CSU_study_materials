// Simulate the SaveHistory procedure from calculator_pro_90plus.asm
// This verifies the HISTORY.TXT generation logic
const fs = require('fs');
const path = require('path');

// The ASM code writes to D:\HISTORY.TXT
const HIST_PATH = 'D:\\HISTORY.TXT';

// Simulate a calculation: expression "3.2 + 4.5" = 7.70
const expression = '3.2 + 4.5';
const result = 770; // fixed point: 7.70 * 100

// Simulate MakeFixedString: converts result to string "7.70"
function makeFixedString(value) {
    let str = '';
    if (value < 0) {
        str = '-';
        value = -value;
    }
    const intPart = Math.floor(value / 100);
    const fracPart = value % 100;
    str += intPart.toString();
    str += '.';
    str += fracPart.toString().padStart(2, '0');
    return str;
}

const resultStr = makeFixedString(result);

// Simulate what SaveHistory writes:
// inputBuf+2 (expression) + " = " + resultStr + CRLF
const line = expression + ' = ' + resultStr + '\r\n';

console.log('=== Simulating SaveHistory ===');
console.log('Target file:', HIST_PATH);
console.log('Expression:', expression);
console.log('Result (fixed *100):', result);
console.log('Result string:', resultStr);
console.log('Line to write:', JSON.stringify(line));

try {
    // Try to append to the file (same as ASM code: open existing or create new, then append)
    let fd;
    try {
        fd = fs.openSync(HIST_PATH, 'a'); // open for append
        console.log('Opened existing file for append.');
    } catch (e) {
        fd = fs.openSync(HIST_PATH, 'w'); // create new
        console.log('Created new file.');
    }

    fs.appendFileSync(fd, line);
    fs.closeSync(fd);

    // Verify
    const content = fs.readFileSync(HIST_PATH, 'utf8');
    console.log('\n=== File contents after write ===');
    console.log(content);
    console.log('=== File exists at:', HIST_PATH, '===');
    console.log('File size:', fs.statSync(HIST_PATH).size, 'bytes');
    console.log('\nSUCCESS: HISTORY.TXT was generated!');

} catch (err) {
    console.error('ERROR writing to HISTORY.TXT:', err.message);
    console.log('\nTrying alternative path...');

    // Try project directory as fallback
    const altPath = path.join(__dirname, 'HISTORY.TXT');
    console.log('Alternative path:', altPath);

    try {
        fs.appendFileSync(altPath, line);
        console.log('Written to alternative path successfully.');
        console.log('Content:', fs.readFileSync(altPath, 'utf8'));
    } catch (e2) {
        console.error('Also failed:', e2.message);
    }
}
