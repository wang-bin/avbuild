#/bin/bash
echo
echo "FFmpeg build tool for all platforms. Author: wbsecg1@gmail.com 2013-2016"

PLATFORMS="ios|android|maemo5|maemo6|vc|x86|winstore|winpc|winphone"
echo "Usage:"
test -d $PWD/ffmpeg || echo "  export FFSRC=/path/to/ffmpeg"
echo "  ./build_ffmpeg.sh [${PLATFORMS} [arch]]"
echo "(optional) set var in config-xxx.sh, xxx is ${PLATFORMS//\|/, }"
echo "var can be: INSTALL_DIR, NDK_ROOT, MAEMO5_SYSROOT, MAEMO6_SYSROOT"
TAGET_FLAG=$1
TAGET_ARCH_FLAG=$2 #${2:-$1}

if [ -n "$TAGET_FLAG" ]; then
  USER_CONFIG=config-${TAGET_FLAG}.sh
  test -f $USER_CONFIG &&  . $USER_CONFIG
fi

: ${INSTALL_DIR:=sdk}
# set NDK_ROOT if compile for android
: ${NDK_ROOT:="/devel/android/android-ndk-r10e"}
: ${MAEMO5_SYSROOT:=/opt/QtSDK/Maemo/4.6.2/sysroots/fremantle-arm-sysroot-20.2010.36-2-slim}
: ${MAEMO6_SYSROOT:=/opt/QtSDK/Madde/sysroots/harmattan_sysroot_10.2011.34-1_slim}
: ${LIB_OPT:="--enable-shared --disable-static"}
: ${MISC_OPT="--enable-hwaccels"}#--enable-gpl --enable-version3

: ${FFSRC:=$PWD/ffmpeg}
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
  local name=$1
#TODO: osx=>darwin
  local line=`uname -a |grep -i $name`
  test -n "$line" && return 0 || return 1
}
target_is() {
  test "$TAGET_FLAG" = "$1" && return 0 || return 1
}
target_arch_is() {
  test "$TAGET_ARCH_FLAG" = "$1" && return 0 || return 1
}
is_libav() {
  test "${PWD/libav*/}" = "$PWD" && return 1 || return 0
}
host_is MinGW || host_is MSYS && {
  echo "msys2: change target_os detect in configure: mingw32)=>mingw*|msys*)"
  echo "       pacman -Sy --needed diffutils pkg-config"
  echo 'export PATH=$PATH:$MINGW_BIN:$PWD # make.exe in mingw_builds can not deal with windows driver dir. use msys2 make instead'
}

enable_opt() {
  local OPT=$1
  # grep -m1
  grep "\-\-enable\-$OPT" $FFSRC/configure && eval ${OPT}_opt="--enable-$OPT" &>/dev/null
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
# clock_gettime in librt instead of glibc>=2.17
grep "LIBRT" $FFSRC/configure &>/dev/null && {
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
# http://ffmpeg.org/platform.html#Microsoft-Visual-C_002b_002b-or-Intel-C_002b_002b-Compiler-for-Windows
  #TOOLCHAIN_OPT=
  test -n "$dxva2_opt" && PLATFORM_OPT="$PLATFORM_OPT $dxva2_opt"
  PLATFORM_OPT="$PLATFORM_OPT --toolchain=msvc"
  CL_INFO=`cl 2>&1 |grep -i Microsoft`
  CL_VER=`echo $CL_INFO |sed 's,.* \([0-9]*\)\.[0-9]*\..*,\1,g'`
  echo "cl version: $CL_VER"
  if [ -n "`echo $CL_INFO |grep -i x86`" ]; then
    echo "vc x86"
    INSTALL_DIR="${INSTALL_DIR}-vc-x86"
    test $CL_VER -gt 16 && echo "adding windows xp compatible link flags..." && PLATFORM_OPT="$PLATFORM_OPT --extra-ldflags=\"-SUBSYSTEM:CONSOLE,5.01\""
  elif [ -n "`echo $CL_INFO |grep -i x64`" ]; then
    INSTALL_DIR="${INSTALL_DIR}-vc-x66"
    echo "vc x64"
    test $CL_VER -gt 16 && echo "adding windows xp compatible link flags..." && PLATFORM_OPT="$PLATFORM_OPT --extra-ldflags=\"-SUBSYSTEM:CONSOLE,5.02\""
  elif [ -n "`echo $CL_INFO |grep -i arm`" ]; then
    INSTALL_DIR="${INSTALL_DIR}-vc-arm"
    echo "vc arm"
    # http://www.cnblogs.com/zjjcy/p/3384517.html  http://www.cnblogs.com/zjjcy/p/3499848.html
    # armasm: http://www.cnblogs.com/zcmmwbd/p/windows-phone-8-armasm-guide.html#2842650
    # TODO: use a wrapper function to deal with the parameters passed to armasm
    PLATFORM_OPT="--extra-cflags=\"-D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE -D_M_ARM -DWINAPI_FAMILY=WINAPI_FAMILY_APP\" --extra-ldflags=\"-MACHINE:ARM\" $PLATFORM_OPT --enable-cross-compile --arch=arm --cpu=armv7 --target-os=win32 --as=armasm --disable-yasm --disable-inline-asm"
  fi
}

setup_winrt_env() {
#http://fate.libav.org/arm-msvc-14-wp
  MISC_OPT="$MISC_OPT --disable-programs --disable-encoders --disable-muxers --disable-avdevice"
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --toolchain=msvc --enable-cross-compile --target-os=win32"
  CL_INFO=`cl 2>&1 |grep -i Microsoft`
  CL_VER=`echo $CL_INFO |sed 's,.* \([0-9]*\)\.[0-9]*\..*,\1,g'`
  INSTALL_DIR=winrt

  echo "cl version: $CL_VER"
  local winver="0x0A00"
  test $CL_VER -lt 19 && winver="0x0603"
  local family="WINAPI_FAMILY_APP"
  EXTRA_CFLAGS="$EXTRA_CFLAGS -MD"
  EXTRA_LDFLAGS="-APPCONTAINER"
  local arch=x86_64 #used by configure --arch
  if [ -n "`echo $CL_INFO |grep -i arm`" ]; then
    # asm broken: table
    # fft_vfp.S is broken in 87552d54d3337c3241e8a9e1a05df16eaa821496 (good c30eb74d182063c85a895c6fd3c9d47b93370bb0)
    # jrevdct_arm.S is broken in 77cdfde73e91cdbcc82cdec6b8fec6f646b02782 and use "libavutil/arm/asm.S" (good 2ad4c241c852efc0baa79b21db6bbc87c27873ef)
    ASM_OPT="--as=armasm --cpu=armv7-a --disable-neon --enable-vfp --enable-thumb"
    which cpp &>/dev/null || {
      echo "ASM is disabled: cpp is required by gas-preprocessor but it is missing. make sure (mingw) gcc is in your PATH"
      ASM_OPT=--disable-asm
    }
    #gas-preprocessor.pl change open(INPUT, "-|", @preprocess_c_cmd) || die "Error running preprocessor"; to open(INPUT, "@preprocess_c_cmd|") || die "Error running preprocessor";
    EXTRA_CFLAGS="$EXTRA_CFLAGS -D__ARM_PCS_VFP"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -MACHINE:ARM"
    arch="arm"
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT $ASM_OPT"
  elif [ -n "`echo $CL_INFO |grep -i x64`" ]; then
    arch=x86_64
  else
    arch=x86
  fi
  local winphone=N
  target_is winstore && test "x$WIN_PHONE" != "x" && winphone=Y
  target_is winphone && winphone=Y
  if [ "$winphone" == "Y" ]; then
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
  echo "INSTALL_DIR=$INSTALL_DIR"
}

setup_mingw_env() {
  echo "TOOLCHAIN_OPT=$TOOLCHAIN_OPT"
  host_is MinGW || host_is MSYS || return 1
    test -n "$dxva2_opt" && PLATFORM_OPT="$PLATFORM_OPT $dxva2_opt"
    TOOLCHAIN_OPT="$dxva2_opt --disable-iconv $TOOLCHAIN_OPT --extra-ldflags=\"-static-libgcc -Wl,-Bstatic\""
  # check host_is mingw64 is not enough
  if [ -n "`gcc -dumpmachine |grep -i x86_64`" ]; then
    INSTALL_DIR="${INSTALL_DIR}-mingw64"
  else
    INSTALL_DIR="${INSTALL_DIR}-mingw32"
  fi
}

setup_icc_env() {
  #TOOLCHAIN_OPT=
  PLATFORM_OPT="--toolchain=icl"
}

setup_wince_env() {
  WINCEOPT="--enable-cross-compile --cross-prefix=arm-mingw32ce- --target-os=mingw32ce --arch=arm --cpu=arm"
  PLATFORM_OPT="$WINCEOPT"
  MISC_OPT=
  INSTALL_DIR=sdk-wince
}

setup_android_env() {
  local ANDROID_ARCH=$1
  test -n "$ANDROID_ARCH" || ANDROID_ARCH=arm
  local ANDROID_TOOLCHAIN_PREFIX="${ANDROID_ARCH}-linux-android"
  local CROSS_PREFIX=${ANDROID_TOOLCHAIN_PREFIX}-
  local FFARCH=$ANDROID_ARCH
  local PLATFORM=android-9 #ensure do not use log2f in libm
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-lto"
  if [ "$ANDROID_ARCH" = "x86" -o "$ANDROID_ARCH" = "i686" ]; then
    ANDROID_TOOLCHAIN_PREFIX="x86"
    CROSS_PREFIX=i686-linux-android-
  elif [ ! "${ANDROID_ARCH/arm/}" = "arm" ]; then
#https://wiki.debian.org/ArmHardFloatPort/VfpComparison
    ANDROID_TOOLCHAIN_PREFIX="arm-linux-androideabi"
    CROSS_PREFIX=${ANDROID_TOOLCHAIN_PREFIX}-
    FFARCH=arm
    EXTRA_CFLAGS="$EXTRA_CFLAGS -ffast-math -fstrict-aliasing -Werror=strict-aliasing -Wa,--noexecstack"
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-thumb"
    if [ ! "${ANDROID_ARCH/armv5/}" = "$ANDROID_ARCH" ]; then
      echo "armv5"
      #EXTRA_CFLAGS="$EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
    elif [ ! "${ANDROID_ARCH/neon/}" = "$ANDROID_ARCH" ]; then
      echo "neon. can not run on Marvell and nVidia"
      TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-neon" #--cpu=cortex-a8
      EXTRA_CFLAGS="$EXTRA_CFLAGS -march=armv7-a -mfloat-abi=softfp -mfpu=neon -mvectorize-with-neon-quad"
      #EXTRA_LDFLAGS="$EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
    else
      TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-neon"
      EXTRA_CFLAGS="$EXTRA_CFLAGS -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
    fi
  elif [ "$ANDROID_ARCH" = "aarch64" ]; then
    PLATFORM=android-21
  fi
  local TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.9
  [ -d $NDK_ROOT/toolchains/${TOOLCHAIN} ] || TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.8
  local ANDROID_TOOLCHAIN_DIR="/tmp/ndk-$TOOLCHAIN"
  echo "ANDROID_TOOLCHAIN_DIR=${ANDROID_TOOLCHAIN_DIR}"
  local ANDROID_SYSROOT="$ANDROID_TOOLCHAIN_DIR/sysroot"
# --enable-libstagefright-h264
  ANDROIDOPT="--enable-cross-compile --cross-prefix=$CROSS_PREFIX --sysroot=$ANDROID_SYSROOT --target-os=android --arch=${FFARCH}"
  test -d $ANDROID_TOOLCHAIN_DIR || $NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=$PLATFORM --toolchain=$TOOLCHAIN --install-dir=$ANDROID_TOOLCHAIN_DIR #--system=linux-x86_64
  export PATH=$ANDROID_TOOLCHAIN_DIR/bin:$PATH
  rm -rf $ANDROID_SYSROOT/usr/include/{libsw*,libav*}
  rm -rf $ANDROID_SYSROOT/usr/lib/{libsw*,libav*}
  #MISC_OPT=--disable-avdevice
  PLATFORM_OPT="$ANDROIDOPT"
  INSTALL_DIR=sdk-android-$ANDROID_ARCH
  # more flags see: https://github.com/yixia/FFmpeg-Vitamio/blob/vitamio/build_android.sh
}

setup_ios_env() {
#iphoneos iphonesimulator i386
# https://github.com/yixia/FFmpeg-Vitamio/blob/vitamio/build_ios.sh
  local IOS_ARCH=$1
  ## cc="xcrun -sdk iphoneos clang"
  PLATFORM_OPT="--enable-cross-compile --arch=$IOS_ARCH --target-os=darwin --cc='xcrun -sdk iphonesimulator clang' --sysroot=\$(xcrun --sdk iphoneos --show-sdk-path)"
  LIB_OPT="--enable-static"
  MISC_OPT="$MISC_OPT --disable-avdevice --disable-programs"
  EXTRA_CFLAGS="-arch $IOS_ARCH -miphoneos-version-min=6.0"
  EXTRA_LDFLAGS="-arch $IOS_ARCH -miphoneos-version-min=6.0"
  INSTALL_DIR=sdk-ios-$IOS_ARCH
}

setup_ios_simulator_env() {
#iphoneos iphonesimulator i386
# clang -arch i386 -arch x86_64
  local IOS_ARCH=$1
  PLATFORM_OPT="--enable-cross-compile --arch=$IOS_ARCH --cpu=$IOS_ARCH --target-os=darwin --cc='xcrun -sdk iphoneos clang' --sysroot=\$(xcrun --sdk iphonesimulator --show-sdk-path)"
  LIB_OPT="--enable-static"
  MISC_OPT="$MISC_OPT --disable-avdevice --disable-programs"
  EXTRA_CFLAGS="-arch $IOS_ARCH -mios-simulator-version-min=6.0"
  EXTRA_LDFLAGS="-arch $IOS_ARCH -mios-simulator-version-min=6.0"
  INSTALL_DIR=sdk-ios-$IOS_ARCH
}

setup_maemo5_env() {
#--arch=armv7l --cpu=armv7l
#CLANG=clang
  if [ -n "$CLANG" ]; then
    CLANG_CFLAGS="-target arm-none-linux-gnueabi"
    CLANG_LFLAGS="-target arm-none-linux-gnueabi"
    HOSTCC=clang
    MAEMO_OPT="--host-cc=$HOSTCC --cc=$HOSTCC --enable-cross-compile  --target-os=linux --arch=armv7-a --sysroot=$MAEMO5_SYSROOT"
  else
    HOSTCC=gcc
    MAEMO_OPT="--host-cc=$HOSTCC --cross-prefix=arm-none-linux-gnueabi- --enable-cross-compile --target-os=linux --arch=armv7-a --sysroot=$MAEMO5_SYSROOT"
  fi
  PLATFORM_OPT="$MAEMO_OPT"
  MISC_OPT=$MISC_OPT --disable-avdevice
  INSTALL_DIR=sdk-maemo5
}
setup_maemo6_env() {
#--arch=armv7l --cpu=armv7l
#CLANG=clang
  if [ -n "$CLANG" ]; then
    CLANG_CFLAGS="-target arm-none-linux-gnueabi"
    CLANG_LFLAGS="-target arm-none-linux-gnueabi"
    HOSTCC=clang
    MAEMO_OPT="--host-cc=$HOSTCC --cc=$HOSTCC --enable-cross-compile  --target-os=linux --arch=armv7-a --sysroot=$MAEMO6_SYSROOT"
  else
    HOSTCC=gcc
    MAEMO_OPT="--host-cc=$HOSTCC --cross-prefix=arm-none-linux-gnueabi- --enable-cross-compile --target-os=linux --arch=armv7-a --sysroot=$MAEMO6_SYSROOT"
  fi
  PLATFORM_OPT="$MAEMO_OPT"
  MISC_OPT=$MISC_OPT --disable-avdevice
  INSTALL_DIR=sdk-maemo6
}

MORE_OPT=0
if target_is android; then
  setup_android_env $TAGET_ARCH_FLAG
  MORE_OPT=1
elif target_is ios; then
  setup_ios_env $TAGET_ARCH_FLAG
elif target_is ios_simulator; then
  setup_ios_simulator_env $TAGET_ARCH_FLAG
elif target_is vc; then
  setup_vc_env
elif target_is winpc; then
  setup_winrt_env
elif target_is winphone; then
  setup_winrt_env
elif target_is winstore; then
  setup_winrt_env
elif target_is maemo5; then
  setup_maemo5_env
elif target_is maemo6; then
  setup_maemo6_env
elif target_is x86; then
  MORE_OPT=1
  if [ "`uname -m`" = "x86_64" ]; then
    #TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --target-os=$(tolower $(uname -s)) --arch=x86"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -m32"
    EXTRA_CFLAGS="$EXTRA_CFLAGS -m32"
    INSTALL_DIR=sdk-x86
  fi
else
  if host_is Sailfish; then
    echo "Build in Sailfish SDK"
    MISC_OPT=$MISC_OPT --disable-avdevice
    INSTALL_DIR=sdk-sailfish
  elif host_is Linux; then
    test -n "$vaapi_opt" && PLATFORM_OPT="$PLATFORM_OPT $vaapi_opt"
    test -n "$vdpau_opt" && PLATFORM_OPT="$PLATFORM_OPT $vdpau_opt"
  elif host_is Darwin; then
    test -n "$vda_opt" && PLATFORM_OPT="$PLATFORM_OPT $vda_opt"
    test -n "$videotoolbox_opt" && PLATFORM_OPT="$PLATFORM_OPT $videotoolbox_opt"
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --cc=clang" #libav has no --cxx
    EXTRA_CFLAGS=-mmacosx-version-min=10.6
  fi
  MORE_OPT=1
fi

if [ $MORE_OPT -eq 1 ]; then
  EXTRA_CFLAGS="$EXTRA_CFLAGS -O3"
  setup_mingw_env || TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-lto"
  # wrong! detect target!=host
fi
test -n "$EXTRA_CFLAGS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-cflags=\"$EXTRA_CFLAGS\""
test -n "$EXTRA_LDFLAGS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldflags=\"$EXTRA_LDFLAGS\""
test -n "$EXTRALIBS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-libs=\"$EXTRALIBS\""
echo $LIB_OPT
is_libav || MISC_OPT="$MISC_OPT --enable-avresample --disable-postproc"
CONFIGURE="configure --extra-version=QtAV --disable-doc --disable-debug $LIB_OPT --enable-pic --enable-runtime-cpudetect $USER_OPT $MISC_OPT $PLATFORM_OPT $TOOLCHAIN_OPT"
CONFIGURE=`echo $CONFIGURE |tr -s ' '`
# http://ffmpeg.org/platform.html
# static: --enable-pic --extra-ldflags="-Wl,-Bsymbolic" --extra-ldexeflags="-pie"
# ios: https://github.com/FFmpeg/gas-preprocessor

JOBS=2
if which nproc >/dev/null; then
    JOBS=`nproc`
elif host_is Darwin && which sysctl >/dev/null; then
    JOBS=`sysctl -n machdep.cpu.thread_count`
fi
echo $CONFIGURE
mkdir -p build_$INSTALL_DIR
cd build_$INSTALL_DIR
time eval $CONFIGURE
if [ $? -eq 0 ]; then
  time (make -j$JOBS install prefix="$PWD/../$INSTALL_DIR")
fi

# --enable-pic is default  --enable-lto
# http://cmzx3444.iteye.com/blog/1447366
# --enable-openssl  --enable-hardcoded-tables  --enable-librtmp --enable-zlib
