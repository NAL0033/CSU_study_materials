@echo off
echo ==============================================
echo   MASM 6.11 - Assembling CALC.ASM...
echo ==============================================
\masm\MASM CALC.ASM;
echo.
echo ==============================================
echo   LINK - Linking CALC.OBJ...
echo ==============================================
\masm\LINK CALC.OBJ;
echo.
echo Build Complete! Run CALC.EXE to test.
