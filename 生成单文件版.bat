@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================
echo 秦腔脸谱 - 生成 Chrome 通用单文件版
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_make_embedded.ps1"
echo.
echo ============================================
echo 完成。按任意键退出
pause >nul
