:: set PKG_CONFIG_PATH_MFX=%CD%\VS2019\lib\pkgconfig
if [%MSYSTEM%] == [] goto SetupMSYS2

:SetupAV
set CPP_DIR=
:: Platform is defined by vcvarsall.bat. use %ARCH% is fine too
if /i "%Platform%" == "arm" (
  set CPP_DIR=%MSYS2_DIR%\mingw64\bin
  if not exist %CPP_DIR%\cpp.exe set CPP_DIR=%MSYS2_DIR%\mingw32\bin
)
set PATH_CLEAN=%PATH_CLEAN%;%CPP_DIR%
set PATH=%PATH%;%CPP_DIR%
set HOME=%~dp0..
set TARGET_PARAM=
if [%VC_BUILD%] == [true] set TARGET_PARAM=vc
if [%WINRT%] == [true] set TARGET_PARAM=winstore
if /i not [%ARCH%] == [all] set TARGET_PARAM=%TARGET_PARAM% %ARCH%
@echo Now you can run:
@echo export FFSRC=/path/to/ffmpeg
@echo ./avbuild.sh

:: --login -x is verbose
if [%BUILD_NOW%] == [] goto StartBash

%MSYS2_DIR%\usr\bin\bash.exe --login avbuild.sh %TARGET_PARAM%
goto end

:StartBash
%MSYS2_DIR%\usr\bin\bash.exe --login -i

goto END

:SetupMSYS2
if exist %~dp0msys2.bat call %~dp0msys2.bat
goto END

:END
