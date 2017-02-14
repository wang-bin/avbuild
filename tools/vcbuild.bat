:: this file only contains vc environemnt settings
:: Copyright (c) 2017 wang bin <wbsecg1 at gmail.com>

:: vcbuild <msvc_ver|vs_ver|cl_ver> <desktop|phone|store> <version(5.1,6.1,6.2,10)> <arch>
:: vcbuild <msvc_ver|vs_ver|cl_ver> <xp|vista|win7|win8,win8.1|win10|winphone8.1|winstore10> <arch>
:: windows version affects compiler and linker flags (-D_WIN32_WINNT=)
:: msvc_ver: vs2013, vs2015, vs2017; vs_ver: VS120, VS140; cl_ver: cl18, cl19
:: prefer highest vs compiler from env

@echo off
set MSYS2_PATH_TYPE=inherit
set VC_BUILD=true
set VS_CL=%1
if [%VS_CL%] == [] set /P VS_CL="VS CL name, e.g. vs2015, vs140, cl1900: "

set VSVER=140
if /i [%VS_CL:~0,2%] == [vs] (
    set VSVER=%VS_CL:~2%
    if [%VS_CL:~2%] == [2015] set VSVER=140
    if [%VS_CL:~2%] == [2013] set VSVER=120
    if [%VS_CL:~2%] == [2012] set VSVER=110
)
:: vs2017 cl1910
if /i [%VS_CL:~0,2%] == [cl] (
    if [%VS_CL:~2,2%] == [19] set VSVER=140
    if [%VS_CL:~2,2%] == [18] set VSVER=120
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

:: TODO vs2017 layout changes
set ARCH=%3
if [%ARCH%] == [] set /P ARCH="architecture (x86, x64, arm): "

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

:: setlocal enableDelayedExpansion
:: set VCDIR=!%VS%VSVER%COMNTOOLS%!
:: endlocal
call set VCDIR=%%VS%VSVER%COMNTOOLS%%
echo VCDIR VS%VSVER%COMNTOOLS=%VCDIR%
call "%VCDIR%\..\..\VC\vcvarsall.bat" %ARG%

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
SET LIBPATH=%WindowsSdkDir%References\CommonConfiguration\Neutral;%VSINSTALLDIR%VC\lib\%ARCH2%;
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
