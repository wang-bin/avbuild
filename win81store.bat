set ARCH=%1
set ARCH2=%ARCH%
set ARG=x86_%ARCH%
if "%ARCH%" == "x86" (
  set ARCH2=
  set ARG=x86
)
if "%ARCH%" == "x64" (
  set ARCH2=amd64
  set ARG=x86_amd64
)

echo "Now you can setup msys2 environment."
echo "For example, run: C:\msys64\msys2_shell.bat"
echo "Then in the msys2 window, run ./build_ffmpeg.sh winrt"

%comspec% /k ""%VS120COMNTOOLS%\..\..\VC\vcvarsall.bat"" %ARG%

:: the following code will not be called
SET LIB=%VSINSTALLDIR%VC\lib\store\%ARCH2%;%VSINSTALLDIR%VC\atlmfc\lib\%ARCH2%;%WindowsSdkDir%lib\winv6.3\um\%ARCH%;;
SET LIBPATH=%WindowsSdkDir%References\CommonConfiguration\Neutral;;%VSINSTALLDIR%VC\atlmfc\lib\%ARCH2%;%VSINSTALLDIR%VC\lib\%ARCH2%;
SET INCLUDE=%VSINSTALLDIR%VC\include;%VSINSTALLDIR%VC\atlmfc\include;%WindowsSdkDir%Include\um;%WindowsSdkDir%Include\shared;%WindowsSdkDir%Include\winrt;
set WINRT=yes
