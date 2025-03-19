@echo off
echo Checking Python installation...
where python >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Python is required but not installed. Please install Python and try again.
    exit /b 1
)

echo Installing required packages...
python -m pip install requests colorama --quiet

echo Starting SERP API test client...
python "%~dp0test_serp_api.py" %*
pause