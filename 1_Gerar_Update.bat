@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>nul
if %errorlevel%==0 (
  set "PY=py -3"
) else (
  set "PY=python"
)

%PY% tools\updater\updater_tool.py build
echo.
echo Update gerado. Para abrir testando o auto updater, rode 2_Abrir_Client_AutoUpdater.bat
pause
