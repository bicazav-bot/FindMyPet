@echo off
chcp 65001 >nul
title FindMyPet
cd /d "%~dp0"
echo ============================================
echo   FindMyPet - instalar, compilar e iniciar
echo ============================================

where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo No se encontro Node.js. Intentando instalarlo con winget...
  winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
  echo.
  echo Si Node.js se instalo, CIERRE esta ventana y vuelva a abrir INICIAR_WINDOWS.bat.
  echo Si no, descarguelo de https://nodejs.org ^(version LTS^) e intente de nuevo.
  pause
  exit /b 1
)
for /f "delims=" %%v in ('node -v') do echo Node.js %%v

if not exist "server\node_modules" (
  echo.
  echo [1/3] Instalando dependencias del backend...
  call npm install --prefix server
  if errorlevel 1 goto error
)
if not exist "client\node_modules" (
  echo.
  echo [2/3] Instalando dependencias del frontend...
  call npm install --prefix client
  if errorlevel 1 goto error
)

echo.
echo [3/3] Compilando el frontend...
call npm run build --prefix client
if errorlevel 1 goto error

echo.
node scripts\local.js %*
pause
exit /b 0

:error
echo.
echo Ocurrio un error. Revise los mensajes de arriba.
pause
exit /b 1
