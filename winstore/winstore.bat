@echo off
set VCDIR=%VS140COMNTOOLS%
if /i %1 == win81 set VCDIR=%VS120COMNTOOLS%
set ARCH=%2
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
set WIN_VER=8.1
set WIN_PHONE=%3
call "%VS120COMNTOOLS%\..\..\VC\vcvarsall.bat" %ARG%

@if "%WIN_VER%" == "8.1" goto SetEnv81
@if "%WIN_VER%" == "10" goto SetEnv10

:SetEnv81
@if "%WIN_PHONE%" == "phone" goto SetEnvPhone81
@SET LIB=%VSINSTALLDIR%VC\lib\store\%ARCH2%;%VSINSTALLDIR%VC\atlmfc\lib\%ARCH2%;%WindowsSdkDir%lib\winv6.3\um\%ARCH%;;
@SET LIBPATH=%WindowsSdkDir%References\CommonConfiguration\Neutral;;%VSINSTALLDIR%VC\atlmfc\lib\%ARCH2%;%VSINSTALLDIR%VC\lib\%ARCH2%;
@SET INCLUDE=%VSINSTALLDIR%VC\include;%VSINSTALLDIR%VC\atlmfc\include;%WindowsSdkDir%Include\um;%WindowsSdkDir%Include\shared;%WindowsSdkDir%Include\winrt;
@goto end

:SetEnvPhone81
@SET WindowsPhoneKitDir=%WindowsSdkDir%..\..\Windows Phone Kits\8.1
@SET LIB=%VSINSTALLDIR%VC\lib\store\%ARCH2%;%VSINSTALLDIR%VC\atlmfc\lib;%WindowsPhoneKitDir%\lib\%ARCH%;;
@SET LIBPATH=%VSINSTALLDIR%VC\atlmfc\lib\%ARCH2%;%VSINSTALLDIR%VC\lib\%ARCH2%
@SET INCLUDE=%VSINSTALLDIR%VC\INCLUDE;%VSINSTALLDIR%VC\ATLMFC\INCLUDE;%WindowsPhoneKitDir%\Include;%WindowsPhoneKitDir%\Include\abi;%WindowsPhoneKitDir%\Include\mincore;%WindowsPhoneKitDir%\Include\minwin;%WindowsPhoneKitDir%\Include\wrl;
@goto end

:SetEnv10
@SET LIB=%VSINSTALLDIR%VC\lib\store;%VSINSTALLDIR%VC\atlmfc\lib;%UniversalCRTSdkDir%lib\%UCRTVersion%\ucrt\%ARCH%;;%UniversalCRTSdkDir%lib\%UCRTVersion%\um\%ARCH%;C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6\lib\um\%ARCH%;;C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6\Lib\um\%ARCH%
@SET LIBPATH=%VSINSTALLDIR%VC\atlmfc\lib\%ARCH2%;%VSINSTALLDIR%VC\lib\%ARCH2%;
@SET INCLUDE=%VSINSTALLDIR%VC\include;%VSINSTALLDIR%VC\atlmfc\include;%UniversalCRTSdkDir%Include\%UCRTVersion%\ucrt;%UniversalCRTSdkDir%Include\%UCRTVersion%\um;%UniversalCRTSdkDir%Include\%UCRTVersion%\shared;%UniversalCRTSdkDir%Include\%UCRTVersion%\winrt;C:\Program Files (x86)\Windows Kits\NETFXSDK\4.6\Include\um;
@goto end

:end
@echo INCLUDE=%INCLUDE%
@echo LIB=%LIB%
@echo LIBPATH=%LIBPATH%
@echo "Now you can run:"
@echo "cd dir/of/build_ffmpeg"
@echo "export PATH=$PATH:ffmpeg_source_dir"
@echo "./build_ffmpeg.sh winstore"
call ..\msys2.bat
