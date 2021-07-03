:: set PKG_CONFIG_PATH_MFX=%CD%\VS2019\lib\pkgconfig
echo user.bat

if  /i [%HOST_WSL%] == [true] goto SetWSL

:SetMSYS
echo SetMSYS
if [%MSYSTEM%] == [] goto SetupMSYS2
dir %MSYS2_DIR%

set CPP_DIR=
:: Platform is defined by vcvarsall.bat. use %ARCH% is fine too
if /i "%Platform%" == "arm" (
  set CPP_DIR=%MSYS2_DIR%\mingw64\bin
  if not exist %CPP_DIR%\cpp.exe set CPP_DIR=%MSYS2_DIR%\mingw32\bin
)
set PATH_CLEAN=%PATH_CLEAN%;%CPP_DIR%
set PATH=%PATH%;%CPP_DIR%
set BASH_CMD=%MSYS2_DIR%\usr\bin\bash.exe --login
goto SetupAV

:SetWSL
set BASH_CMD=bash
echo DO NOT forget to install nasm yasm pkg-config
goto SetupAV



:SetupAV
set HOME=%~dp0..
set PWD=%~dp0..
set TARGET_PARAM=
if [%VC_BUILD%] == [true] set TARGET_PARAM=vc
if [%WINRT%] == [true] set TARGET_PARAM=winstore
if /i not [%ARCH%] == [all] set TARGET_PARAM=%TARGET_PARAM% %ARCH%
@echo Now you can run:
@echo export FFSRC=/path/to/ffmpeg
@echo ./avbuild.sh #%TARGET_PARAM%

:: --login -x is verbose
if [%BUILD_NOW%] == [] goto StartBash

echo Start to build: %BASH_CMD% avbuild.sh %TARGET_PARAM%
%BASH_CMD% avbuild.sh %TARGET_PARAM%

goto end

:StartBash
echo StartBash %BASH_CMD%  -i
%BASH_CMD%  -i

goto END

:SetupMSYS2
echo SetupMSYS2
if exist %~dp0msys2.bat call %~dp0msys2.bat
goto END

:END
