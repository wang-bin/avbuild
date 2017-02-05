#/bin/bash
# TODO: -flto=nb_cpus
# %MSYS2_BIN% --login -x %~dp0build_ffmpeg.sh vc
# MXE cross toolchain
echo
echo "FFmpeg build tool for all platforms. Author: wbsecg1@gmail.com 2013-2016"
echo "https://github.com/wang-bin/build_ffmpeg"

PLATFORMS="ios|android|maemo|vc|x86|winstore|winpc|winphone|mingw64"
echo "Usage:"
test -d $PWD/ffmpeg || echo "  export FFSRC=/path/to/ffmpeg"
cat<<HELP
./build_ffmpeg.sh [target_platform [target_architecture]]
target_platform can be: ${PLATFORMS}
target_architecture can be:
   ios   |  android  |  mingw64
         |   armv5   |
  armv7  |   armv7   |
  arm64  |   arm64   |
x86/i366 |  x86/i686 |  x86/i686
 x86_64  |   x86_64  |   x86_64
If no parameter is passed, build for the host platform compiler.
Use a shortcut in winstore to build for WinRT target.
Use ios.sh to build for iOS universal target.
If target_platform is ios, mininal ios version(major.minor) can be specified by suffix, e.g. ios5.0
(Optional) set var in config-xxx.sh, xxx is ${PLATFORMS//\|/, }
var can be: INSTALL_DIR, NDK_ROOT, MAEMO_SYSROOT
config.sh will be automatically included.
config-lite.sh is options to build smaller libraries.
HELP

TAGET_FLAG=$1
TAGET_ARCH_FLAG=$2 #${2:-$1}

test -f config.sh && . config.sh
USER_CONFIG=config-${TAGET_FLAG}.sh
test -f $USER_CONFIG &&  . $USER_CONFIG

# TODO: use USER_OPT only
: ${INSTALL_DIR:=sdk}
# set NDK_ROOT if compile for android
: ${NDK_ROOT:="/devel/android/android-ndk-r10e"}
: ${MAEMO5_SYSROOT:=/opt/QtSDK/Maemo/4.6.2/sysroots/fremantle-arm-sysroot-20.2010.36-2-slim}
: ${MAEMO6_SYSROOT:=/opt/QtSDK/Madde/sysroots/harmattan_sysroot_10.2011.34-1_slim}
: ${LIB_OPT:="--enable-shared"}
: ${FEATURE_OPT:="--enable-hwaccels"} #--enable-gpl --enable-version3
: ${DEBUG_OPT:="--disable-debug"}

: ${FFSRC:=$PWD/ffmpeg}
: ${enable_lto:=true}

echo FFSRC=$FFSRC
[ -f $FFSRC/configure ] && {
  export PATH=$PATH:$FFSRC
} || {
  which configure &>/dev/null || {
    echo 'ffmpeg configure script can not be found in "$PATH"'
    exit 0
  }
  FFSRC=`which configure`
  FFSRC=${FFSRC%/configure}
}

toupper(){
    echo "$@" | tr abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ
}

tolower(){
    echo "$@" | tr ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz
}

host_is() {
  uname |grep -iq $1 && return 0 || return 1
}
target_is() {
  test "$TAGET_FLAG" = "$1" && return 0 || return 1
}
target_arch_is() {
  test "$TAGET_ARCH_FLAG" = "$1" && return 0 || return 1
}
is_libav() {
  test -f "$FFSRC/avconv.c" && return 0 || return 1
}
add_ffopt() {
  # check opt exitsts (--enable/disable), do nothing if exists
  echo "not implemented"
}
host_is MinGW || host_is MSYS && {
  echo "msys2: change target_os detect in configure: mingw32)=>mingw*|msys*)"
  echo "       pacman -Sy --needed diffutils pkg-config mingw-w64-i686-gcc mingw-w64-x86_64-gcc"
  echo 'export PATH=$PATH:$MINGW_BIN:$PWD # make.exe in mingw_builds can not deal with windows driver dir. use msys2 make instead'
}

enable_opt() {
  local OPT=$1
  # grep -m1
  grep -q "\-\-enable\-$OPT" $FFSRC/configure && eval ${OPT}_opt="--enable-$OPT"
}
#CPU_FLAGS=-mmmx -msse -mfpmath=sse
#ffmpeg 1.2 autodetect dxva, vaapi, vdpau. manually enable vda before 2.3
enable_opt dxva2
host_is Linux && {
  enable_opt vaapi
  enable_opt vdpau
}
host_is Darwin && {
  enable_opt vda
  enable_opt videotoolbox
}

enable_vtenc(){
  test -f $FFSRC/libavcodec/videotoolboxenc.c && echo "$USER_OPT" |grep -q "disable-encoders" && USER_OPT="$USER_OPT --enable-encoder=*_videotoolbox"
}
# clock_gettime in librt instead of glibc>=2.17
grep -q "LIBRT" $FFSRC/configure && {
  # TODO: cc test
  host_is Linux && ! target_is android && EXTRALIBS="$EXTRALIBS -lrt"
}
#avr >= ffmpeg0.11
#FFMAJOR=`pwd |sed 's,.*-\(.*\)\..*\..*,\1,'`
#FFMINOR=`pwd |sed 's,.*\.\(.*\)\..*,\1,'`
# n1.2.8, 2.5.1, 2.5
cd $FFSRC
FFMAJOR=`./version.sh |sed 's,[a-zA-Z]*\([0-9]*\)\..*,\1,'`
FFMINOR=`./version.sh |sed 's,[a-zA-Z]*[0-9]*\.\([0-9]*\).*,\1,'`
cd -
echo "FFmpeg/Libav version: $FFMAJOR.$FFMINOR"

setup_vc_env() {
  LIB_OPT="$LIB_OPT --disable-static"
  echo Call "set MSYS2_PATH_TYPE=inherit" before msys2 sh.exe if cl.exe is not found!
# http://ffmpeg.org/platform.html#Microsoft-Visual-C_002b_002b-or-Intel-C_002b_002b-Compiler-for-Windows
  test -n "$dxva2_opt" && FEATURE_OPT="$FEATURE_OPT $dxva2_opt"
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --toolchain=msvc"
  VS_VER=${VisualStudioVersion:0:2}
  echo "VS version: $VS_VER, platform: $Platform"
  if [ "`tolower $Platform`" = "x64" ]; then
    INSTALL_DIR="${INSTALL_DIR}-vc-x64"
    echo "vc x64"
    test $VS_VER -gt 10 && echo "adding windows xp compatible link flags..." && EXTRA_LDFLAGS="-SUBSYSTEM:CONSOLE,5.02"
  elif [ "`tolower $Platform`" = "arm" ]; then
    INSTALL_DIR="${INSTALL_DIR}-vc-arm"
    echo "use scripts in winstore dir instead"
    exit 0
  else #Platform is empty
    echo "vc x86"
    INSTALL_DIR="${INSTALL_DIR}-vc-x86"
    test $VS_VER -gt 10 && echo "adding windows xp compatible link flags..." && EXTRA_LDFLAGS="-SUBSYSTEM:CONSOLE,5.01"
  fi
}

setup_winrt_env() {
  LIB_OPT="$LIB_OPT --disable-static"
#http://fate.libav.org/arm-msvc-14-wp
  FEATURE_OPT="--disable-programs $FEATURE_OPT" # prepend so that user can overwrite
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --toolchain=msvc --enable-cross-compile --target-os=win32"
  VS_VER=${VisualStudioVersion:0:2}
  echo "vs version: $VS_VER, platform: $Platform"
  INSTALL_DIR=winrt

  echo "vs version: $VS_VER"
  local winver="0x0A00"
  test $VS_VER -lt 14 && winver="0x0603"
  local family="WINAPI_FAMILY_APP"
  EXTRA_CFLAGS="$EXTRA_CFLAGS -MD"
  EXTRA_LDFLAGS="-APPCONTAINER"
  local arch=x86_64 #used by configure --arch
  if [ "`tolower $Platform`" = "arm" ]; then
    ASM_OPT="--as=armasm --cpu=armv7-a --enable-thumb" # --arch
    which cpp &>/dev/null || {
      echo "ASM is disabled: cpp is required by gas-preprocessor but it is missing. make sure (mingw) gcc is in your PATH"
      ASM_OPT=--disable-asm
    }
    #gas-preprocessor.pl change open(INPUT, "-|", @preprocess_c_cmd) || die "Error running preprocessor"; to open(INPUT, "@preprocess_c_cmd|") || die "Error running preprocessor";
    EXTRA_CFLAGS="$EXTRA_CFLAGS -D__ARM_PCS_VFP"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -MACHINE:ARM"
    arch="arm"
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT $ASM_OPT"
  elif [ "`tolower $Platform`" = "x64" ]; then
    arch=x86_64
  else
    arch=x86
  fi
  local winphone=false
  target_is winstore && test -n "$WIN_PHONE" && winphone=true
  target_is winphone && winphone=true
  if $winphone; then
  # export dirs (lib, include)
    family="WINAPI_FAMILY_PHONE_APP"
    INSTALL_DIR=winphone
    # phone ldflags only for win8.1?
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -subsystem:console -opt:ref WindowsPhoneCore.lib RuntimeObject.lib PhoneAppModelHost.lib -NODEFAULTLIB:kernel32.lib -NODEFAULTLIB:ole32.lib"
  fi
  if [ "$winver" == "0x0603" ]; then
    INSTALL_DIR="${INSTALL_DIR}81${arch}"
  else
    INSTALL_DIR="${INSTALL_DIR}10${arch}"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS WindowsApp.lib"
  fi
  EXTRA_CFLAGS="$EXTRA_CFLAGS -DWINAPI_FAMILY=$family -D_WIN32_WINNT=$winver"
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --arch=$arch"
}

setup_mingw_env() {
  LIB_OPT="$LIB_OPT --disable-static"
  enable_lto=false
  local gcc=gcc
  host_is MinGW -o host_is MSYS || {
    local arch=$1
    [ "$arch" = "x86" ] && arch=i686
    gcc=${arch}-w64-mingw32-gcc
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --cross-prefix=${arch}-w64-mingw32- --target-os=mingw32 --arch=$arch"
  }
  test -n "$dxva2_opt" && FEATURE_OPT="$FEATURE_OPT $dxva2_opt"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -static-libgcc -Wl,-Bstatic"
  FEATURE_OPT="--disable-iconv $FEATURE_OPT"
  $gcc -dumpmachine |grep -iq x86_64 && INSTALL_DIR="${INSTALL_DIR}-mingw-x64" || INSTALL_DIR="${INSTALL_DIR}-mingw-x86"
}

setup_wince_env() {
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --cross-prefix=arm-mingw32ce- --target-os=mingw32ce --arch=arm --cpu=arm"
  INSTALL_DIR=sdk-wince
}

setup_android_env() {
  local ANDROID_ARCH=$1
  test -n "$ANDROID_ARCH" || ANDROID_ARCH=arm
  local ANDROID_TOOLCHAIN_PREFIX="${ANDROID_ARCH}-linux-android"
  local CROSS_PREFIX=${ANDROID_TOOLCHAIN_PREFIX}-
  local FFARCH=$ANDROID_ARCH
  local PLATFORM=android-9 #ensure do not use log2f in libm
#TODO: what if no following default flags (from ndk android.toolchain.cmake)?
  EXTRA_CFLAGS="$EXTRA_CFLAGS -ffast-math -fstrict-aliasing -Werror=strict-aliasing -ffunction-sections -fstack-protector-strong -Wa,--noexecstack -Wformat -Werror=format-security" # " #-funwind-tables need libunwind.a for libc++?
# -no-canonical-prefixes: results in "-mcpu= ", why?
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,--build-id -Wl,--fatal-warnings" # -Wl,--warn-shared-textrel

  if [ "$ANDROID_ARCH" = "x86" -o "$ANDROID_ARCH" = "i686" ]; then
    ANDROID_ARCH=x86
    ANDROID_TOOLCHAIN_PREFIX="x86"
    CROSS_PREFIX=i686-linux-android-
    enable_lto=false
  elif [ "$ANDROID_ARCH" = "x86_64" -o "$ANDROID_ARCH" = "x64" ]; then
    PLATFORM=android-21
    ANDROID_ARCH=x86_64
    ANDROID_TOOLCHAIN_PREFIX="x86_64"
    CROSS_PREFIX=x86_64-linux-android-
    enable_lto=false
  elif [ "$ANDROID_ARCH" = "aarch64" -o "$ANDROID_ARCH" = "arm64" ]; then
    PLATFORM=android-21
    ANDROID_ARCH=arm64
    ANDROID_TOOLCHAIN_PREFIX=aarch64-linux-android
    CROSS_PREFIX=aarch64-linux-android-
  elif [ ! "${ANDROID_ARCH/arm/}" = "${ANDROID_ARCH}" ]; then
#https://wiki.debian.org/ArmHardFloatPort/VfpComparison
    ANDROID_TOOLCHAIN_PREFIX="arm-linux-androideabi"
    CROSS_PREFIX=${ANDROID_TOOLCHAIN_PREFIX}-
    FFARCH=arm
    if [ ! "${ANDROID_ARCH/armv5/}" = "$ANDROID_ARCH" ]; then
      echo "armv5"
      TOOLCHAIN_OPT="$TOOLCHAIN_OPT --cpu=armv5te"
      #EXTRA_CFLAGS="$EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
      CLANG_FLAGS="-target armv5te-none-linux-androideabi"
: '
-mthumb error
selected processor does not support Thumb mode `itt gt
D:\msys2\tmp\ccXOcbBA.s:262: Error: instruction not supported in Thumb16 mode -- adds r3,r1,r0,lsr#31
D:\msys2\tmp\ccXOcbBA.s:263: Error: selected processor does not support Thumb mode itet ne
D:\msys2\tmp\ccXOcbBA.s:264: Error: Thumb does not support conditional execution
use armv6t2 or -mthumb-interwork: https://gcc.gnu.org/onlinedocs/gcc-4.5.3/gcc/ARM-Options.html
'
# -msoft-float == -mfloat-abi=soft https://gcc.gnu.org/onlinedocs/gcc-4.5.3/gcc/ARM-Options.html
      EXTRA_CFLAGS="$EXTRA_CFLAGS -mtune=xscale -msoft-float"
      if [ ! "$android_toolchain" = "clang" ]; then
        EXTRA_CFLAGS="$EXTRA_CFLAGS -mthumb-interwork"
      fi
    else
      TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-thumb --enable-neon"
      EXTRA_CFLAGS="$EXTRA_CFLAGS -march=armv7-a -mtune=cortex-a8 -mfloat-abi=softfp" #-mcpu= is deprecated in gcc 3, use -mtune=cortex-a8 instead
      EXTRA_LDFLAGS="$EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
      CLANG_FLAGS="-target armv7-none-linux-androideabi"
      if [ ! "${ANDROID_ARCH/neon/}" = "$ANDROID_ARCH" ]; then
        enable_lto=false
        echo "neon. can not run on Marvell and nVidia"
        EXTRA_CFLAGS="$EXTRA_CFLAGS -mfpu=neon -mvectorize-with-neon-quad"
      else
        EXTRA_CFLAGS="$EXTRA_CFLAGS -mfpu=vfpv3-d16"
      fi
    fi
    CLANG_FLAGS=" -fno-integrated-as $CLANG_FLAGS"
    ANDROID_ARCH=arm
  fi
  local TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.9
  [ -d $NDK_ROOT/toolchains/${TOOLCHAIN} ] || TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.8
  local ANDROID_TOOLCHAIN_DIR="$NDK_ROOT/toolchains/${TOOLCHAIN}"
  gxx=`find ${ANDROID_TOOLCHAIN_DIR} -name "*g++*"` # can not use "*-gcc*": can be -gcc-ar, stdint-gcc.h
  clangxx=`find $NDK_ROOT/toolchains/llvm/prebuilt -name "clang++*"` # can not be "clang*": clang-tidy
  echo "g++: $gxx, clang++: $clangxx"
  ANDROID_TOOLCHAIN_DIR=${gxx%bin*}
  local ANDROID_LLVM_DIR=${clangxx%bin*}
  echo "ANDROID_TOOLCHAIN_DIR=${ANDROID_TOOLCHAIN_DIR}"
  echo "ANDROID_LLVM_DIR=${ANDROID_LLVM_DIR}"
  CLANG_FLAGS="$CLANG_FLAGS -gcc-toolchain $ANDROID_TOOLCHAIN_DIR"
  local ANDROID_SYSROOT="$NDK_ROOT/platforms/$PLATFORM/arch-${ANDROID_ARCH}"
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --sysroot=$ANDROID_SYSROOT --target-os=android --arch=${FFARCH} --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
  if [ "$android_toolchain" = "clang" ]; then
    enable_lto=false # clang -flto will generate llvm ir bitcode instead of object file
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --cc=clang"
    EXTRA_CFLAGS="$EXTRA_CFLAGS $CLANG_FLAGS"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS $CLANG_FLAGS" # -Qunused-arguments is added by ffmpeg configure
  fi
  #test -d $ANDROID_TOOLCHAIN_DIR || $NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=$PLATFORM --toolchain=$TOOLCHAIN --install-dir=$ANDROID_TOOLCHAIN_DIR #--system=linux-x86_64
  export PATH=$ANDROID_TOOLCHAIN_DIR/bin:$ANDROID_LLVM_DIR/bin:$PATH
  clang --version
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldexeflags=\"-Wl,--gc-sections -Wl,-z,nocopyreloc -pie -fPIE\""
  INSTALL_DIR=sdk-android-${1:-${ANDROID_ARCH}}-${android_toolchain:-gcc}
  enable_opt mediacodec
  test -n "$mediacodec_opt" && FEATURE_OPT="$mediacodec_opt --enable-jni $FEATURE_OPT"
}
#  --toolchain=hardened : https://wiki.debian.org/Hardening
setup_ios_env() {
# TODO: multi arch (Xarch+arch)
# clang -arch i386 -arch x86_64
## cc="xcrun -sdk iphoneos clang" or cc=`xcrun -sdk iphoneos --find clang`
  local IOS_ARCH=$1
  local cc_has_bitcode=false # bitcode since xcode 7
  clang -fembed-bitcode -E - </dev/null &>/dev/null && cc_has_bitcode=true
  : ${BITCODE:=true}
  local enable_bitcode=false
  $BITCODE && $cc_has_bitcode && enable_bitcode=true
  # bitcode link requires iOS>=6.0. Creating static lib is fine. So compiling with bitcode for <5.0 is fine. but ffmpeg config tests fails to create exe(ios10 sdk, no crt1.3.1.o), so 6.0 is required
  $enable_bitcode && echo "Bitcode is enabled by default. Run 'BITCODE=false ./ios.sh' to disable bitcode"
# http://iossupportmatrix.com
  local ios_min=6.0
  local SYSROOT_SDK=iphoneos
  local VER_OS=iphoneos
  local BITCODE_FLAGS=
  if [ "${IOS_ARCH:0:3}" == "arm" ]; then
    $enable_bitcode && BITCODE_FLAGS="-fembed-bitcode"
    # armv7 since 3.2, but latest ios sdk does not have crt1.o/crt1.3.1.o, so use 6.0.
    if [ "${IOS_ARCH:3:2}" == "64" ]; then
      ios_min=7.0
    fi
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-thumb"
  else
    SYSROOT_SDK=iphonesimulator
    VER_OS=ios-simulator
    if [ "${IOS_ARCH}" == "x86_64" ]; then
      ios_min=7.0
    elif [ "${IOS_ARCH}" == "x86" ]; then
      IOS_ARCH=i386
    fi
  fi
  ios_ver=${2##ios}
  : ${ios_ver:=$ios_min}
  export LIBRARY_PATH=$PWD/lib/ios5
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --arch=$IOS_ARCH --target-os=darwin --cc=clang --sysroot=\$(xcrun --sdk $SYSROOT_SDK --show-sdk-path)"
  FEATURE_OPT="$FEATURE_OPT --disable-programs" #FEATURE_OPT
  EXTRA_CFLAGS="-arch $IOS_ARCH -m${VER_OS}-version-min=$ios_ver $BITCODE_FLAGS"
  EXTRA_LDFLAGS="-arch $IOS_ARCH -m${VER_OS}-version-min=$ios_ver" #No bitcode flags for iOS < 6.0. we always build static libs. but config test will try to create exe
  enable_vtenc
  INSTALL_DIR=sdk-ios-$IOS_ARCH
}

setup_maemo_env() {
#--arch=armv7l --cpu=armv7l
#CLANG=clang
  if [ -z "$MAEMO_SYSROOT" ]; then
    test $1 = 5 && MAEMO_SYSROOT=$MAEMO5_SYSROOT || MAEMO_SYSROOT=$MAEMO6_SYSROOT
  fi
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --target-os=linux --arch=armv7-a --sysroot=$MAEMO_SYSROOT"
  if [ -n "$CLANG" ]; then
    CLANG_CFLAGS="-target arm-none-linux-gnueabi"
    CLANG_LFLAGS="-target arm-none-linux-gnueabi"
    HOSTCC=clang
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --host-cc=$HOSTCC --cc=$HOSTCC"
  else
    HOSTCC=gcc
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --host-cc=gcc --cross-prefix=arm-none-linux-gnueabi-"
  fi
  INSTALL_DIR=sdk-maemo
}

case $1 in
  android)    setup_android_env $TAGET_ARCH_FLAG ;;
  ios*)       setup_ios_env $TAGET_ARCH_FLAG $1 ;;
  mingw64)    setup_mingw_env $TAGET_ARCH_FLAG ;;
  vc)         enable_lto=false && setup_vc_env ;; # TODO: test lto
  winpc|winphone|winrt) setup_winrt_env ;;    # TODO: test lto
  maemo*)     setup_maemo_env ${1##maemo} ;;
  x86)
    if [ "`uname -m`" = "x86_64" ]; then
      #TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --target-os=$(tolower $(uname -s)) --arch=x86"
      EXTRA_LDFLAGS="$EXTRA_LDFLAGS -m32"
      EXTRA_CFLAGS="$EXTRA_CFLAGS -m32"
      INSTALL_DIR=sdk-x86
    fi
    ;;
  *) # assume host build. use "") ?
    if host_is MinGW || host_is MSYS; then
      setup_mingw_env
    elif host_is Linux; then
      test -n "$vaapi_opt" && FEATURE_OPT="$FEATURE_OPT $vaapi_opt"
      test -n "$vdpau_opt" && FEATURE_OPT="$FEATURE_OPT $vdpau_opt"
    elif host_is Darwin; then
      enable_vtenc
      test -n "$vda_opt" && FEATURE_OPT="$FEATURE_OPT $vda_opt"
      test -n "$videotoolbox_opt" && FEATURE_OPT="$FEATURE_OPT $videotoolbox_opt"
      grep -q install-name-dir $FFSRC/configure && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --install_name_dir=@rpath"
      # 10.6: ld: warning: target OS does not support re-exporting symbol _av_gettime from libavutil/libavutil.dylib
      EXTRA_CFLAGS="-mmacosx-version-min=10.7" #TODO ./build_ffmpeg.sh macOS10.6
      EXTRA_LDFLAGS="-mmacosx-version-min=10.7 -Wl,-rpath,@loader_path -Wl,-rpath,@loader_path/../Frameworks -Wl,-rpath,@loader_path/lib -Wl,-rpath,@loader_path/../lib"
    elif host_is Sailfish; then
      echo "Build in Sailfish SDK"
      INSTALL_DIR=sdk-sailfish
    fi
    ;;
esac

$enable_lto && [ ! "${LIB_OPT/disable-static/}" == "${LIB_OPT}" ] && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-lto"

target_is winstore || TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-pic" # armasm(gas) error (unsupported option) if pic is enabled
test -n "$EXTRA_CFLAGS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-cflags=\"$EXTRA_CFLAGS\""
test -n "$EXTRA_LDFLAGS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldflags=\"$EXTRA_LDFLAGS\""
test -n "$EXTRALIBS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-libs=\"$EXTRALIBS\""
echo INSTALL_DIR: $INSTALL_DIR
echo $LIB_OPT
is_libav || FEATURE_OPT="$FEATURE_OPT --enable-avresample --disable-postproc"
CONFIGURE="configure --extra-version=QtAV --disable-doc ${DEBUG_OPT} $LIB_OPT --enable-runtime-cpudetect $FEATURE_OPT $FEATURE_OPT $TOOLCHAIN_OPT $USER_OPT"
CONFIGURE=`echo $CONFIGURE |tr -s ' '`
# http://ffmpeg.org/platform.html
# static: --enable-pic --extra-ldflags="-Wl,-Bsymbolic" --extra-ldexeflags="-pie"

JOBS=2
if which nproc >/dev/null; then
    JOBS=`nproc`
elif host_is Darwin && which sysctl >/dev/null; then
    JOBS=`sysctl -n machdep.cpu.thread_count`
fi
echo $CONFIGURE
mkdir -p build_$INSTALL_DIR
cd build_$INSTALL_DIR
time (eval $CONFIGURE)
if [ $? -eq 0 ]; then
  time (make -j$JOBS install prefix="$PWD/../$INSTALL_DIR" && echo $CONFIGURE >>$PWD/../$INSTALL_DIR/config.txt)
fi

# http://cmzx3444.iteye.com/blog/1447366
# --enable-openssl  --enable-hardcoded-tables  --enable-librtmp --enable-zlib
