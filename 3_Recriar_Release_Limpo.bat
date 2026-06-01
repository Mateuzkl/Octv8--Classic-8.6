@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>nul
if %errorlevel%==0 (
  set "PY=py -3"
) else (
  set "PY=python"
)

%PY% tools\updater\updater_tool.py build --rebuild-release
echo.
echo Release protegido recriado em release_client.
echo O data.zip fica embutido no executavel quando a protecao estiver ativa.
pause
