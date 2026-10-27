@echo off
rem ================================================================
rem  One-click updater for the delivered folder.
rem  Usage: drag "update-v*.zip" onto this bat, or put the zip next to
rem  this file and double-click the bat.
rem  It backs up old html into .\backup\ then replaces html / exe / txt,
rem  and removes older versioned html files (so the folder never has two
rem  versions to double-click by mistake).
rem  Your data lives in the browser (localStorage), so nothing is lost.
rem  NOTE: keep this file ASCII-only (cmd parses .bat in OEM code page).
rem ================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "ZIP=%~1"
if not "%ZIP%"=="" goto :havezip
for %%F in (update-v*.zip) do set "ZIP=%%~fF"
:havezip
if "%ZIP%"=="" goto :nozip
if not exist "%ZIP%" goto :nozip

echo Updating from: "%ZIP%"
set "TMPD=%TEMP%\classpts_upd_%RANDOM%%RANDOM%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%TMPD%' -Force"
if errorlevel 1 goto :fail

if not exist "backup" mkdir "backup"
set "UPDATED=0"
set "NEWHTML="

for %%H in ("%TMPD%\*.html") do (
  set "NEWHTML=%%~nxH"
  if exist "%%~nxH" copy /y "%%~nxH" "backup\%%~nxH.bak" >nul
  copy /y "%%H" "%%~nxH" >nul
  echo   updated: %%~nxH
  set "UPDATED=1"
)

for %%E in ("%TMPD%\*.exe") do (
  taskkill /f /im "%%~nxE" >nul 2>nul
  copy /y "%%E" "%%~nxE" >nul
  echo   updated: %%~nxE
  set "UPDATED=1"
)

for %%T in ("%TMPD%\*.txt") do (
  if exist "%%~nxT" copy /y "%%~nxT" "backup\%%~nxT.bak" >nul
  copy /y "%%T" "%%~nxT" >nul
  echo   updated: %%~nxT
  set "UPDATED=1"
)

rem Remove other versioned html files (keep only the freshly copied one)
for %%O in (*_v*.html) do (
  if /i not "%%~nxO"=="!NEWHTML!" (
    if exist "backup\%%~nxO.bak" (del /f /q "%%~nxO" >nul) else (copy /y "%%~nxO" "backup\%%~nxO.bak" >nul & del /f /q "%%~nxO" >nul)
    echo   removed old: %%~nxO
  )
)

rmdir /s /q "%TMPD%" >nul 2>nul

echo.
if "!UPDATED!"=="0" (
  echo Nothing was updated - the zip did not contain html / exe / txt files.
  echo Please use the official "update-vX.Y.zip".
) else (
  echo Done. Old files are backed up in .\backup\
  echo Data stored in the browser is NOT affected.
)
echo.
pause
exit /b 0

:nozip
echo.
echo No update package found.
echo Put "update-vX.Y.zip" next to this bat, or drag the zip onto this bat.
echo.
pause
exit /b 1

:fail
echo.
echo Extract failed. Close the running program / browser and try again,
echo or replace html + exe manually from the zip.
echo.
pause
exit /b 1
