:: set your MSYS2_DIR here
set MSYS2_DIR=D:\msys2
:: use vc to build ffmpeg. set to other value to use mingw toolchain
set VC_BUILD=true

set CPP_DIR=
if "%ARCH%" == "arm" (
  set CPP_DIR=%MSYS2_DIR%\mingw64\bin
  if not exist %CPP_DIR%\cpp.exe set CPP_DIR=%MSYS2_DIR%\mingw32\bin
)
set PATH=%PATH%;%CPP_DIR%
set TARGET_PARAM=vc
if [%WINRT%] == [true] set TARGET_PARAM=winstore
@echo Now you can run:
@echo cd dir/of/build_ffmpeg
@echo export FFSRC=/path/to/ffmpeg
@echo ./build_ffmpeg.sh or ./build_ffmpeg %TARGET_PARAM%

if not exist %MSYS2_DIR% goto NoBash
%MSYS2_DIR%\usr\bin\bash.exe --login -i
goto end

:NoBash
echo "Please setup your MSYS2_DIR correctly in msys2.bat. for example: set MSYS2_DIR=C:\msys64"
echo "Or you can setup msys2 environment."
echo "For example, run: C:\msys64\msys2_shell.cmd"
goto end

:end