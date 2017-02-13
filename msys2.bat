@echo off
:: set your MSYS2_DIR here
if [%MSYS2_DIR%] == [] set MSYS2_DIR=D:\msys2


:: -------------------DO NOT CHANGE THE FOLLOWING CODE------------------------
set CC_ARG=%1%
set OS_ARG=%2%
set ARCH_ARG=%3%
:: VC_BUILD is checked in avbuild.sh host build.
set VC_BUILD=true
if /i [%CC_ARG%] == [gcc] (
:: MSYSTEM MUST use upper case
  if /i [%OS_ARG%] == [mingw] set MSYSTEM=MINGW%ARCH_ARG%
  set MINGW_BUILD=true
  set VC_BUILD=false
)

set CPP_DIR=
if "%ARCH%" == "arm" (
  set CPP_DIR=%MSYS2_DIR%\mingw64\bin
  if not exist %CPP_DIR%\cpp.exe set CPP_DIR=%MSYS2_DIR%\mingw32\bin
)
set PATH=%PATH%;%CPP_DIR%
set TARGET_PARAM=
if [%VC_BUILD%] == [true] set TARGET_PARAM=vc
if [%WINRT%] == [true] set TARGET_PARAM=winstore
@echo Now you can run:
@echo export FFSRC=/path/to/ffmpeg
@echo ./avbuild.sh
if not [%TARGET_PARAM%] == [] @echo or ./avbuild %TARGET_PARAM%

if not exist %MSYS2_DIR% goto NoBash
set HOME=%~dp0
:: TODO: set MSYSTEM=MINGW32 for armasm to use cpp.exe?
:: --login -x is verbose
if [%BUILD_NOW%] == [] goto StartBash

%MSYS2_DIR%\usr\bin\bash.exe --login avbuild.sh
goto end

:StartBash
%MSYS2_DIR%\usr\bin\bash.exe --login -i

goto end

:NoBash
echo "Please setup your MSYS2_DIR correctly in msys2.bat. for example: set MSYS2_DIR=C:\msys64"
echo "Or you can setup msys2 environment."
echo "For example, run: C:\msys64\msys2_shell.cmd"
goto end

:end