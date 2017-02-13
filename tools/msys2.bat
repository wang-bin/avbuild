:: this file only contains msys2 environemnt settings
:: Copyright (c) 2017 wang bin <wbsecg1 at gmail.com>

@echo off
:: set your MSYS2_DIR here
if [%MSYS2_DIR%] == [] set MSYS2_DIR=D:\msys2
if not exist %MSYS2_DIR% set MSYS2_DIR=C:\msys64

:: -------------------DO NOT CHANGE THE FOLLOWING CODE------------------------
set CC_ARG=%1%
set OS_ARG=%2%
set ARCH_ARG=%3%
set MSYSTEM=MSYS
if /i [%CC_ARG%] == [gcc] (
:: MSYSTEM MUST use upper case
  if /i [%OS_ARG%] == [mingw] set MSYSTEM=MINGW%ARCH_ARG%
  set MINGW_BUILD=true
)

if not exist %MSYS2_DIR% goto NoBash
set HOME=%~dp0
if exist %~dp0user.bat call %~dp0user.bat
goto end

:NoBash
echo "Please setup your environment var MSYS2_DIR. For example C:\msys64"
goto end

:end
