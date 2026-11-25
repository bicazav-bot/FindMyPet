@echo off
chcp 65001 >nul
title FindMyPet - pruebas
cd /d "%~dp0"
if not exist "server\node_modules" call npm install --prefix server
node scripts\local.js --probar
pause
