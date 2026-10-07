@echo off
setlocal enabledelayedexpansion

REM ===== Configuration =====
REM Set the directory to scan (use "." for the current directory)
set "TARGET_DIR=."
REM Output file name
set "OUTPUT_FILE=results.txt"

REM ===== Clear or create results file =====
> "%OUTPUT_FILE%" echo File listing for: %TARGET_DIR%
>> "%OUTPUT_FILE%" echo ============================
>> "%OUTPUT_FILE%" echo.

REM ===== Enumerate files =====
set /a counter=0
for /f "delims=" %%F in ('dir /b /a-d "%TARGET_DIR%" 2^>nul') do (
    set /a counter+=1
    >> "%OUTPUT_FILE%" echo !counter!. %%F
)

REM ===== Summary =====
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo Total files: !counter!

echo Done. !counter! file(s) written to %OUTPUT_FILE%
endlocal
