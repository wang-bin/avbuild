:: this file only contains vc environemnt settings
:: Copyright (c) 2017-2018 wang bin <wbsecg1 at gmail.com>

:: vcbuild <msvc_ver|vs_ver|cl_ver> <desktop|phone|store> <version(5.1,6.1,6.2,10)/sdk_version(8.1,10.0.15063.0)> <arch>
:: vcbuild <msvc_ver|vs_ver|cl_ver> <xp|vista|win7|win8,win8.1|win10|winphone8.1|winstore10> <arch>
:: windows version affects compiler and linker flags (-D_WIN32_WINNT=)
:: msvc_ver: vs2013, vs2015, vs2017; vs_ver: VS120, VS140; cl_ver: cl18, cl19
:: prefer highest vs compiler from env

@echo off
set MSYS2_PATH_TYPE=inherit
set PATH_CLEAN=%PATH%
set VC_BUILD=true
set VS_CL=%1
if [%VS_CL%] == [] set /P VS_CL="VS CL name, e.g. vs2019 vs2017 vs2015, vs140, cl1900: "

set VSVER=150
set CL_VER=191
if /i [%VS_CL:~0,2%] == [vs] (
    set VSVER=%VS_CL:~2%
    if [%VS_CL:~2%] == [2015] set VSVER=140
    if [%VS_CL:~2%] == [2013] set VSVER=120
    if [%VS_CL:~2%] == [2012] set VSVER=110
    set VCRT_VER=$VSVER
    if [%VS_CL:~2%] == [2017] (
        set VSVER=150
        set VCRT_VER=141
    )
    if [%VS_CL:~2%] == [2019] (
        set VSVER=160
        set VCRT_VER=142
    )
)
:: vs2017 cl1910
if /i [%VS_CL:~0,2%] == [cl] (
    if [%VS_CL:~2,2%] == [18] set VSVER=120
    if [%VS_CL:~2,2%] == [19] set VSVER=140
    set VCRT_VER=$VSVER
    if [%VS_CL:~2,3%] == [191] (
        set VSVER=150
        set VCRT_VER=141
    )
    if [%VS_CL:~2,3%] == [192] (
        set VSVER=160
        set VCRT_VER=142
    )
)
echo VS_CL=%VS_CL%
echo VSVER=%VSVER%

:: ------OS----------
:: only check winphone? desktop compiler is not limited
set OS=%2
if [%OS%] == [] set /P OS="OS name (xp, vista, win7, win8, win8.1, win10, winphone80, winphone81, winstore10, winphone, winstore): "

set WINRT=false
set WINSTORE=false
set WINPHONE=false
if not [%OS:phone=%] == [%OS%] (
    set WINRT=true
    set WINSTORE=true
    set WINPHONE=true
)
if not [%OS:store=%] == [%OS%] (
    set WINRT=true
    set WINSTORE=true
)

set OS_VER=%OS:~-2%
:: store/phone compiler is limited
if not [%OS%] == [%OS:phone80=%] set VSVER=110
if not [%OS%] == [%OS:phone81=%] set VSVER=120
if not [%OS%] == [%OS:store=%] (
    if [%VSVER%] == [140] set OS_VER=10
    if [%VSVER%] == [120] set OS_VER=81
    if [%VSVER%] == [110] set OS_VER=80
)
if not [%OS%] == [%OS:phone=%] (
    if [%VSVER%] == [140] set OS_VER=10
    if [%VSVER%] == [120] set OS_VER=81
    if [%VSVER%] == [110] set OS_VER=80
)

set ARCH=%3
if [%ARCH%] == [] set /P ARCH="architecture (x86, x64, arm, arm64): "

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

if [%VSVER%] == [150] goto SetupVC150Env
if [%VSVER%] == [160] goto SetupVC160Env

goto SetupVCEnvLegacy

:SetupVC160Env
for /f "usebackq tokens=*" %%i in (`vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set VS_INSTALL_DIR=%%i
)
set VCVARSALL_BAT=%VS_INSTALL_DIR%\VC\Auxiliary\Build\vcvarsall.bat
goto SetupVCEnv

:SetupVC150Env
:: copy from https://github.com/Leandros/VisualStudioStandalone
:: Registry keys.
set VS_KEY="HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7"
set VS_VAL="15.0"
set WIN_SDK_KEY="SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots"
set WIN_SDK_VAL="KitsRoot10"

:: Find out where Visual Studio is installed.
FOR /F "usebackq skip=2 tokens=1-2*" %%A IN (`REG QUERY %VS_KEY% /v %VS_VAL% 2^>nul`) DO (
    set VS_INSTALL_DIR=%%C
)
if not defined VS_INSTALL_DIR (
    echo No Visual Studio installation found!
    exit /B 1
)
echo Visual Studio installation found at %VS_INSTALL_DIR%

:: Get current Visual Studio version.
set VS_TOOLS="%VS_INSTALL_DIR%\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt"
set /p VS_TOOLS_VERSION=<%VS_TOOLS%
set VS_TOOLS_VERSION=%VS_TOOLS_VERSION: =%
set VCVARSALL_BAT=%VS_INSTALL_DIR%\VC\Auxiliary\Build\vcvarsall.bat
echo Using tools version %VS_TOOLS_VERSION%
goto SetupVCEnv

:SetupVCEnv
if [%WINRT%] == [true] set EXTRA_ARGS=store
:: TODO: sdk version, or pass all vcvarsall.bat parameters to support old windows target, onecore etc
if not [%ARCH%] == [all] (
    call "%VCVARSALL_BAT%" %ARG% %EXTRA_ARGS%
    goto end
)

call "%VCVARSALL_BAT%" x86_arm64 %EXTRA_ARGS%
set PATH_arm64=%PATH%
set LIBPATH_arm64=%LIBPATH%
set LIB_arm64=%LIB%
set INCLUDE_arm64=%INCLUDE%
set PATH=%PATH_CLEAN%
set LIB=
set LIBPATH=
set INCLUDE=

goto SetMultiArch


:SetupVCEnvLegacy
:: setlocal enableDelayedExpansion
:: set VCDIR=!%VS%VSVER%COMNTOOLS%!
:: endlocal
call set VCDIR=%%VS%VSVER%COMNTOOLS%%
echo VCDIR VS%VSVER%COMNTOOLS=%VCDIR%
set VCVARSALL_BAT=%VCDIR%\..\..\VC\vcvarsall.bat
call "%VCVARSALL_BAT%" %ARG%

:: default is win10 desktop sdk
if [%WINRT%] == [false] (
	goto SetEnvDesktop
	
)
if [%WINPHONE%] == [true] goto SetEnvPhone81SDK
if [%OS_VER%] == [81] goto SetEnv81SDK
if [%OS_VER%] == [10] (
	set ARG=%ARG% store
	goto SetEnv10SDK
)


:SetMultiArch
:: TODO: vs2013 vcvarsall.bat does not set store env correctly
:: after vcvarsall.bat, main paths are %VCINSTALLDIR%\Tools\MSVC\%VS_TOOLS_VERSION%\bin\HostX86\x86;%WindowsSdkVerBinPath%\x86;%WindowsSdkBinPath%
:: args can be x64, x86_x64, amd64, x86_amd64, amd64_arm64, or simply %HOSTARCH%_x64
call "%VCVARSALL_BAT%" x86_amd64 %EXTRA_ARGS%
set PATH_x64=%PATH%
set LIBPATH_x64=%LIBPATH%
set LIB_x64=%LIB%
set INCLUDE_x64=%INCLUDE%
set PATH=%PATH_CLEAN%
set LIB=
set LIBPATH=
set INCLUDE=

call "%VCVARSALL_BAT%" x86_arm %EXTRA_ARGS%
set PATH_arm=%PATH%
set LIBPATH_arm=%LIBPATH%
set LIB_arm=%LIB%
set INCLUDE_arm=%INCLUDE%
set PATH=%PATH_CLEAN%
set LIB=
set LIBPATH=
set INCLUDE=

:: default is x86, no env reset
call "%VCVARSALL_BAT%" x86 %EXTRA_ARGS%
set PATH_x86=%PATH%
set LIBPATH_x86=%LIBPATH%
set LIB_x86=%LIB%
set INCLUDE_x86=%INCLUDE%

goto end


:SetEnv81SDK
echo "win8.1 sdk"
SET LIB=%VSINSTALLDIR%VC\lib\store\%ARCH2%;%WindowsSdkDir%lib\winv6.3\um\%ARCH%;;
SET LIBPATH=%WindowsSdkDir%References\CommonConfiguration\Neutral;%VSINSTALLDIR%VC\lib\%ARCH2%;
SET INCLUDE=%VSINSTALLDIR%VC\include;%WindowsSdkDir%Include\um;%WindowsSdkDir%Include\shared;%WindowsSdkDir%Include\winrt;
goto end

:SetEnvPhone81SDK
echo win8.1 phone sdk
SET WindowsPhoneKitDir=%WindowsSdkDir%..\..\Windows Phone Kits\8.1
SET LIB=%VSINSTALLDIR%VC\lib\store\%ARCH2%;%WindowsPhoneKitDir%\lib\%ARCH%;
SET LIBPATH=%VSINSTALLDIR%VC\lib\%ARCH2%
SET INCLUDE=%VSINSTALLDIR%VC\INCLUDE;%WindowsSdkDir%Include\um;%WindowsSdkDir%Include\shared;%WindowsSdkDir%Include\winrt;%WindowsPhoneKitDir%\Include;%WindowsPhoneKitDir%\Include\abi;%WindowsPhoneKitDir%\Include\mincore;%WindowsPhoneKitDir%\Include\minwin;%WindowsPhoneKitDir%\Include\wrl;
goto end


:SetEnv10SDK
echo win10 store sdk
SET LIB=%VSINSTALLDIR%VC\lib\store\%ARCH2%;%UniversalCRTSdkDir%lib\%UCRTVersion%\ucrt\%ARCH%;;%UniversalCRTSdkDir%lib\%UCRTVersion%\um\%ARCH%
SET LIBPATH=%VSINSTALLDIR%VC\lib\%ARCH2%;
SET INCLUDE=%VSINSTALLDIR%VC\include;%UniversalCRTSdkDir%Include\%UCRTVersion%\ucrt;%UniversalCRTSdkDir%Include\%UCRTVersion%\um;%UniversalCRTSdkDir%Include\%UCRTVersion%\shared;%UniversalCRTSdkDir%Include\%UCRTVersion%\winrt
goto end

:SetEnvDesktop
if [%VSVER%] == [120] goto SetEnv81DesktopSDK
if [%VSVER%] == [140] goto SetEnv10DesktopSDK

:SetEnv81DesktopSDK
echo "win8.1 desktop sdk"
SET LIB=%VSINSTALLDIR%VC\lib\%ARCH2%;%WindowsSdkDir%lib\winv6.3\um\%ARCH%;;
SET LIBPATH=%VSINSTALLDIR%VC\lib\%ARCH2%;
SET INCLUDE=%VSINSTALLDIR%VC\include;%WindowsSdkDir%Include\um;%WindowsSdkDir%Include\shared;%WindowsSdkDir%Include\winrt;
goto end

:SetEnv10DesktopSDK
echo win10 desktop sdk
SET LIB=%VSINSTALLDIR%VC\lib\%ARCH2%;%UniversalCRTSdkDir%lib\%UCRTVersion%\ucrt\%ARCH%;;%UniversalCRTSdkDir%lib\%UCRTVersion%\um\%ARCH%
SET LIBPATH=%VSINSTALLDIR%VC\lib\%ARCH2%;
SET INCLUDE=%VSINSTALLDIR%VC\include;%UniversalCRTSdkDir%Include\%UCRTVersion%\ucrt;%UniversalCRTSdkDir%Include\%UCRTVersion%\um;%UniversalCRTSdkDir%Include\%UCRTVersion%\shared;%UniversalCRTSdkDir%Include\%UCRTVersion%\winrt
goto end

:end
@echo INCLUDE=%INCLUDE%
@echo LIB=%LIB%
@echo LIBPATH=%LIBPATH%
@echo -------------------------------------------------------------------------------
@echo -----Build environment is ready: %OS% %OS_VER% %ARCH2%. WinRT: %WINRT%-----

if exist %~dp0user.bat call %~dp0user.bat
