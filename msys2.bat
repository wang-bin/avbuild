@echo off
:: set your MSYS2_BIN here
set MSYS2_BIN=D:\build\msys64\usr\bin

if not exist %MSYS2_BIN% goto NoBash
%MSYS2_BIN%\bash.exe --login -i
goto end

:NoBash
echo "Please setup your MSYS2_BIN correctly in msys2.bat. for example: set MSYS2_BIN=C:\msys64\usr\bin"
echo "Or you can setup msys2 environment."
echo "For example, run: C:\msys64\msys2_shell.bat"
goto end

:end