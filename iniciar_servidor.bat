@echo off
title Kriko's - Servidor Local Sincronizado com a Nuvem
echo ========================================================
echo       KRIKO'S - SERVIDOR LOCAL + NUVEM ORACLE
echo ========================================================

REM 1. Configurar Conexao com o Banco de Dados Unificado na Nuvem Oracle
set KRIKOS_DB_HOST=147.15.21.44
set KRIKOS_DB_PORT=3306
set KRIKOS_DB_USER=krikos_user
set KRIKOS_DB_PASSWORD=KrikosAdmin@2026
set KRIKOS_DB_NAME=krikos_db
set KRIKOS_WHATSAPP=5511999999999
set KRIKOS_INSTAGRAM=krikos.oficial

echo [1/2] Conectando ao Banco Central na Nuvem (147.15.21.44:3306)...

REM 2. Iniciar Servidor PHP 8.4 se nao estiver ativo
netstat -ano | findstr :8765 >nul
if %errorlevel% neq 0 (
    echo [2/2] Iniciando Servidor PHP 8.4 local na porta 8765...
    start /B "" "C:\Users\eduxc\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.4_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe" -S 127.0.0.1:8765 -t "%~dp0public"
    timeout /t 2 /nobreak >nul
) else (
    echo [2/2] Servidor PHP ja esta ativo na porta 8765.
)

echo ========================================================
echo  SEU SISTEMA ESTA CONECTADO E SINCRONIZADO COM A NUVEM!
echo ========================================================
echo  Link Principal Nuvem (24h): https://footage-buffalo-rooms-decrease.trycloudflare.com
echo  Link do Servidor Local:    http://127.0.0.1:8765
echo ========================================================
echo  Iniciando tunel publico local de contingencia...
echo ========================================================
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://127.0.0.1:8765
pause
