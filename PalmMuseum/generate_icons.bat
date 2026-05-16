@echo off
chcp 65001 > nul
echo 正在生成图标文件...

powershell -Command "$b=[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='); [System.IO.File]::WriteAllBytes('AppScope\resources\base\media\app_icon.png', $b)"
echo  [OK] AppScope\resources\base\media\app_icon.png

if not exist "entry\src\main\resources\base\media" mkdir "entry\src\main\resources\base\media"
powershell -Command "$b=[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='); [System.IO.File]::WriteAllBytes('entry\src\main\resources\base\media\icon.png', $b)"
echo  [OK] entry\src\main\resources\base\media\icon.png

echo.
echo 图标生成完成！返回 DevEco Studio 重新 Build 即可。
pause
