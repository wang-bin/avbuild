#!/bin/bash
# TODO: -flto=nb_cpus. lto with static build (except android)
# android ndk unified headers
# MXE cross toolchain
# enable cuda
# Unify gcc/clang(elf?) flags(like android): -Wl,-z,now -Wl,-z,-relro -Bsymbolic ...
# https://wiki.debian.org/Hardening#DEB_BUILD_HARDENING_RELRO_.28ld_-z_relro.29
# remove sdl2 in modules
# onecore for store apps
# http://clang.llvm.org/docs/CrossCompilation.html
 
#set -x
echo
echo "FFmpeg build tool for all platforms. Author: wbsecg1@gmail.com 2013-2017"
echo "https://github.com/wang-bin/avbuild"

THIS_NAME=${0##*/}
THIS_DIR=$PWD
PLATFORMS="ios|android|maemo|vc|x86|winstore|winpc|winphone|mingw64"
echo "Usage:"
test -d $PWD/ffmpeg || echo "  export FFSRC=/path/to/ffmpeg"
cat<<HELP
./$THIS_NAME [target_platform [target_architecture]]
target_platform can be: ${PLATFORMS}
target_architecture can be:
 ios(x.y)|  android  |  mingw64
         |   armv5   |
  armv7  |   armv7   |
  arm64  |   arm64   |
x86/i366 |  x86/i686 |  x86/i686
 x86_64  |   x86_64  |   x86_64
If no parameter is passed, build for the host platform compiler.
Use a shortcut in winstore to build for WinRT target.
(Optional) set var in config-xxx.sh, xxx is ${PLATFORMS//\|/, }
var can be: USER_OPT, ANDROID_NDK, MAEMO_SYSROOT
config.sh will be automatically included.
config-lite.sh is default options to build smaller libraries.
HELP

test -f config.sh && . config.sh
USER_CONFIG=config-$1.sh
test -f $USER_CONFIG &&  . $USER_CONFIG

# TODO: use USER_OPT only
# set NDK_ROOT if compile for android
: ${NDK_ROOT:="$ANDROID_NDK"}
: ${LIB_OPT:="--enable-shared"}
#: ${FEATURE_OPT:="--enable-hwaccels"}
: ${DEBUG_OPT:="--disable-debug"}
: {FORCE_LTO:=false}
: ${FFSRC:=$PWD/ffmpeg}
[ ! "${LIB_OPT/disable-static/}" == "${LIB_OPT}" ] && FORCE_LTO=true
# other env vars to control build: NO_ENC, BITCODE, WINPHONE, VC_BUILD, FORCE_LTO (bool)

trap "kill -- -$$; rm -rf $THIS_DIR/.dir exit 3" SIGTERM SIGINT SIGKILL

export PATH=$PWD/tools/gas-preprocessor:$PATH
if [ -n "$PKG_CONFIG_PATH_EXT" ]; then
  export PKG_CONFIG_PATH=$PKG_CONFIG_PATH_EXT # $PKG_CONFIG_PATH/../.. is used in libmfx.pc, so no ":" separated list
  echo ">>>PKG_CONFIG_PATH=$PKG_CONFIG_PATH<<<"
fi

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
FFSRC_TOOLS=$FFSRC/fftools
if ! [ -d "$FFSRC_TOOLS" ]; then
  FFSRC_TOOLS=$FFSRC_TOOLS/avtools
  if ! [ -d "$FFSRC_TOOLS" ]; then
    FFSRC_TOOLS=$FFSRC
  fi
fi
#avr >= ffmpeg0.11
#FFMAJOR=`pwd |sed 's,.*-\(.*\)\..*\..*,\1,'`
#FFMINOR=`pwd |sed 's,.*\.\(.*\)\..*,\1,'`
# n1.2.8, 2.5.1, 2.5
cd $FFSRC
VER_SH=version.sh
[ -f $VER_SH ] || VER_SH=ffbuild/version.sh
[ -f $VER_SH ] || VER_SH=avbuild/version.sh
FFVERSION_FULL=`./$VER_SH`
FFMAJOR=`echo $FFVERSION_FULL |sed 's,[a-zA-Z]*\([0-9]*\)\..*,\1,'`
FFMINOR=`echo $FFVERSION_FULL |sed 's,[a-zA-Z]*[0-9]*\.\([0-9]*\).*,\1,'`
FFGIT=false
[ ${#FFMAJOR} -gt 3 ] && FFGIT=true
cd -
echo "FFmpeg/Libav version: $FFMAJOR.$FFMINOR  git: $FFGIT"

toupper(){
    echo "$@" | tr abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ
}

tolower(){
    echo "$@" | tr ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz
}

trim(){
  local var="$@"
  var="${var#"${var%%[![:space:]]*}"}" #bash4: ${a##+([[:space:]])}
  var="${var%"${var##*[![:space:]]}"}"
  echo -n "$var"
}
# why eval $v=$(trim_compress "\$$v") will have a leading white space (used in trim_vars)?
trim2(){
  trim "$@" |tr -s ' '
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
  test -f "$FFSRC_TOOLS/avconv.c" && return 0 || return 1
}

android_arch(){
  # emulate hash in bash3
  local armv5=armeabi   # ${!armv5} is armeabi<=armeabi<=armv5
  local armv7=armeabi-v7a
  local arm64=arm64-v8a
  # indirect reference
  arch=${!1}
  echo ${arch:=$1}
  return 0
  arch=`eval 'echo ${'$1'}'`
  echo ${arch:=$1}
}

#ffmpeg 1.2 autodetect dxva, vaapi, vdpau. manually enable vda before 2.3
enable_opt() {
  # grep -m1
  for OPT in $@; do
    if grep -q "\-\-enable\-$OPT" $FFSRC/configure; then
      FEATURE_OPT="--enable-$OPT $FEATURE_OPT" # prepend to support override
    fi
  done
}

disable_opt() {
  # grep -m1
  for OPT in $@; do
   if grep -q "\-\-disable\-$OPT" $FFSRC/configure; then
      FEATURE_OPT="--disable-$OPT $FEATURE_OPT" # prepend to support override
    fi
  done
}

enable_libmfx(){
  # TODO: which pkg-config to use for cross build
  if pkg-config --libs libmfx ; then
    enable_opt libmfx
  fi
}

enable_opt hwaccels

add_elf_flags() {
  # -Wl,-z,noexecstack -Wl,--as-needed is added by configure
  EXTRA_CFLAGS="$EXTRA_CFLAGS -fdata-sections -ffunction-sections -fstack-protector-strong"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -Wl,--gc-sections" # -Wl,-z,relro -Wl,-z,now
}

# warnings are used by ffmpeg developer, some are enabled by configure: -Wl,--warn-shared-textrel

setup_vc_env(){
  echo Call "set MSYS2_PATH_TYPE=inherit" before msys2 sh.exe if cl.exe is not found!
  enable_lto=false # ffmpeg requires DCE, while vc with LTCG (-GL) does not support DCE
  LIB_OPT="$LIB_OPT --disable-static"
  # dylink crt
  EXTRA_CFLAGS="$EXTRA_CFLAGS -MD"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -SUBSYSTEM:CONSOLE -NODEFAULTLIB:libcmt" #-NODEFAULTLIB:libcmt -winmd?
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --toolchain=msvc"
  VS_VER=${VisualStudioVersion:0:2}
  echo "VS version: $VS_VER, platform: $Platform" # Platform is from vsvarsall.bat
  FAMILY=
  WIN_VER=
  if $WINRT; then
    setup_winrt_env
  else
    FAMILY=_DESKTOP
    setup_vc_desktop_env
  fi
  EXTRA_CFLAGS="$EXTRA_CFLAGS -D_WIN32_WINNT=$WIN_VER" #  -DWINAPI_FAMILY=WINAPI_FAMILY${FAMILY}_APP is not required for desktop
  INSTALL_DIR="`tolower sdk-vc${VS_VER}$Platform${FAMILY}`"
}

setup_vc_desktop_env() {
# http://ffmpeg.org/platform.html#Microsoft-Visual-C_002b_002b-or-Intel-C_002b_002b-Compiler-for-Windows
  enable_libmfx
  enable_opt dxva2
  # ldflags prepends flags. extralibs appends libs and add to pkg-config
  # can not use -luser32 because extralibs will not be filter -l to .lib (ldflags_filter is not ready, ffmpeg bug)
  # TODO: check dxva2_extralibs="-luser32" in configure
  EXTRALIBS="$EXTRALIBS user32.lib" # ffmpeg 3.x bug: hwcontext_dxva2 GetDesktopWindow()
  if [ "`tolower $Platform`" = "x64" ]; then
    WIN_VER="0x0502"
    test $VS_VER -gt 10 && echo "adding windows xp compatible link flags..." && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldexeflags='-SUBSYSTEM:CONSOLE,5.02'"
  elif [ "`tolower $Platform`" = "arm" ]; then
    echo "use scripts in winstore dir instead"
    exit 1
  else #Platform is empty(native) or x86(cross)
    WIN_VER="0x0501"
    test $VS_VER -gt 10 && echo "adding windows xp compatible link flags..." && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldexeflags='-SUBSYSTEM:CONSOLE,5.01'"
  fi
}

setup_winrt_env() {
  if [ -f "$FFSRC/compat/w32dlfcn.h" ]; then
    grep -q HAVE_WINRT "$FFSRC/compat/w32dlfcn.h" || {
      echo "Patching LoadPackagedLibrary..."
      cp -af patches/0001-winrt-use-LoadPackagedLibrary.patch "$FFSRC/tmp.patch"
      cd "$FFSRC"
      patch -p1 <"tmp.patch"
      cd -
    }
  fi
  if [ -f "$FFSRC/libavutil/hwcontext_d3d11va.c" ]; then
    if ! `grep -q CreateMutexEx "$FFSRC/libavutil/hwcontext_d3d11va.c"`; then
      echo "Patching CreateMutex..."
      cp -af patches/0001-use-CreateMutexEx-instead-of-CreateMutex-to-fix-win8.patch "$FFSRC/tmp.patch"
      cd "$FFSRC"
      patch -p1 <"tmp.patch"
      cd -
    fi
  fi
  #http://fate.libav.org/arm-msvc-14-wp
  disable_opt programs
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --target-os=win32"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -APPCONTAINER"
  WIN_VER="0x0A00"
  test $VS_VER -lt 14 && WIN_VER="0x0603" #FIXME: vc can support multiple target (and sdk)
  WIN10_VER_DEC=`printf "%d" 0x0A00`
  WIN81_VER_DEC=`printf "%d" 0x0603`
  WIN_VER_DEC=`printf "%d" $WIN_VER`
  local arch=x86_64 #used by configure --arch
  if [ "`tolower $Platform`" = "arm" ]; then # TODO: arm64
    enable_pic=false  # TODO: ffmpeg bug, should filter out -fPIC. armasm(gas) error (unsupported option) if pic is
    type -a gas-preprocessor.pl
    ASM_OPT="--as=armasm --cpu=armv7-a --enable-thumb" # --arch
    which cpp &>/dev/null || {
      echo "ASM is disabled: cpp is required by gas-preprocessor but it is missing. make sure (mingw) gcc is in your PATH"
      ASM_OPT=--disable-asm
      enable_pic=true # not tested
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
  : ${WINPHONE:=false}
  target_is winphone && WINPHONE=true
  if $WINPHONE; then
  # export dirs (lib, include)
    FAMILY=_PHONE
    # phone ldflags only for win8.1?
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS -opt:ref WindowsPhoneCore.lib RuntimeObject.lib PhoneAppModelHost.lib -NODEFAULTLIB:kernel32.lib -NODEFAULTLIB:ole32.lib"
  fi
  if [ $WIN_VER_DEC  -gt ${WIN81_VER_DEC} ]; then
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS WindowsApp.lib"
  fi
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --arch=$arch"
  EXTRA_CFLAGS="$EXTRA_CFLAGS -DWINAPI_FAMILY=WINAPI_FAMILY${FAMILY}_APP"
}

setup_mingw_env() {
  LIB_OPT="$LIB_OPT --disable-static"
  enable_lto=false
  local gcc=gcc
  host_is MinGW || host_is MSYS && {
    echo "install msys2 packages: pacman -Sy --needed diffutils gawk patch pkg-config mingw-w64-i686-gcc mingw-w64-x86_64-gcc"
  } || {
    echo "mingw cross build"
    local arch=$1
    [ "$arch" = "x86" ] && arch=i686
    gcc=${arch}-w64-mingw32-gcc
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --cross-prefix=${arch}-w64-mingw32- --target-os=mingw32 --arch=$arch"
  }
  enable_libmfx
  enable_opt dxva2
  disable_opt iconv
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -static-libgcc -Wl,-Bstatic"
  $gcc -dumpmachine |grep -iq x86_64 && INSTALL_DIR="${INSTALL_DIR}-mingw-x64" || INSTALL_DIR="${INSTALL_DIR}-mingw-x86"
}

setup_wince_env() {
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --cross-prefix=arm-mingw32ce- --target-os=mingw32ce --arch=arm --cpu=arm"
  INSTALL_DIR=sdk-wince
}

setup_android_env() {
  ENC_OPT=$ENC_OPT_MOBILE
  MUX_OPT=$MUX_OPT_MOBILE
  disable_opt v4l2_m2m
  local ANDROID_ARCH=$1
  test -n "$ANDROID_ARCH" || ANDROID_ARCH=arm
  local ANDROID_TOOLCHAIN_PREFIX="${ANDROID_ARCH}-linux-android"
  local CROSS_PREFIX=${ANDROID_TOOLCHAIN_PREFIX}-
  local FFARCH=$ANDROID_ARCH
  local API_LEVEL=14 #ensure do not use log2f in libm
  local UNIFIED_SYSROOT="$NDK_ROOT/sysroot"
  [ -d "$UNIFIED_SYSROOT" ] || UNIFIED_SYSROOT=
  add_elf_flags
  EXTRA_CFLAGS="$EXTRA_CFLAGS -ffast-math -fstrict-aliasing" # " #-funwind-tables need libunwind.a for libc++?
# -no-canonical-prefixes: results in "-mcpu= ", why?
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -Wl,-z,relro -Wl,-z,now"
  # TODO: clang lto in r14 (gcc?) except aarch64
  if [ "$ANDROID_ARCH" = "x86" -o "$ANDROID_ARCH" = "i686" ]; then
    ANDROID_ARCH=x86
    ANDROID_TOOLCHAIN_PREFIX=x86
    ANDROID_HEADER_TRIPLE=i686-linux-android
    CROSS_PREFIX=i686-linux-android-
    CLANG_FLAGS="-target i686-none-linux-android"
    # from ndk: x86 devices have stack alignment issues.
    # clang error: inline assembly requires more registers than available ("movzbl "statep"    , "ret")
    [ "$USE_TOOLCHAIN" == "clang" ] || EXTRA_CFLAGS="$EXTRA_CFLAGS -mstackrealign"
    enable_lto=false
  elif [ "$ANDROID_ARCH" = "x86_64" -o "$ANDROID_ARCH" = "x64" ]; then
    API_LEVEL=21
    ANDROID_ARCH=x86_64
    ANDROID_TOOLCHAIN_PREFIX=x86_64
    ANDROID_HEADER_TRIPLE=x86_64-linux-android
    CROSS_PREFIX=x86_64-linux-android-
    CLANG_FLAGS="-target x86_64-none-linux-android"
    enable_lto=false
  elif [ "$ANDROID_ARCH" = "aarch64" -o "$ANDROID_ARCH" = "arm64" ]; then
    API_LEVEL=21
    ANDROID_ARCH=arm64
    ANDROID_TOOLCHAIN_PREFIX=aarch64-linux-android
    ANDROID_HEADER_TRIPLE=aarch64-linux-android
    CROSS_PREFIX=aarch64-linux-android-
    CLANG_FLAGS="-target aarch64-none-linux-android"
  elif [ ! "${ANDROID_ARCH/arm/}" = "${ANDROID_ARCH}" ]; then
#https://wiki.debian.org/ArmHardFloatPort/VfpComparison
    ANDROID_TOOLCHAIN_PREFIX=arm-linux-androideabi
    ANDROID_HEADER_TRIPLE=arm-linux-androideabi
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
      if [ ! "$USE_TOOLCHAIN" = "clang" ]; then
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
    CLANG_FLAGS="-fno-integrated-as $CLANG_FLAGS" # Disable integrated-as for better compatibility. from ndk cmake
    ANDROID_ARCH=arm
  fi
  local TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.9
  [ -d $NDK_ROOT/toolchains/${TOOLCHAIN} ] || TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.8
  local ANDROID_TOOLCHAIN_DIR="$NDK_ROOT/toolchains/${TOOLCHAIN}"
  gxx=`find ${ANDROID_TOOLCHAIN_DIR} -name "*g++*"` # can not use "*-gcc*": can be -gcc-ar, stdint-gcc.h
  clangxxs=(`find $NDK_ROOT/toolchains/llvm/prebuilt -name "clang++*"`) # can not be "clang*": clang-tidy
  clangxx=${clangxxs[0]}
  echo "g++: $gxx, clang++: $clangxx"
  ANDROID_TOOLCHAIN_DIR=${gxx%bin*}
  local ANDROID_LLVM_DIR=${clangxx%bin*}
  echo "ANDROID_TOOLCHAIN_DIR=${ANDROID_TOOLCHAIN_DIR}"
  echo "ANDROID_LLVM_DIR=${ANDROID_LLVM_DIR}"
  ANDROID_TOOLCHAIN_DIR_REL=${ANDROID_TOOLCHAIN_DIR#$NDK_ROOT}
  CLANG_FLAGS="$CLANG_FLAGS -gcc-toolchain \$NDK_ROOT/$ANDROID_TOOLCHAIN_DIR_REL"
  local ANDROID_SYSROOT_LIB="$NDK_ROOT/platforms/android-$API_LEVEL/arch-${ANDROID_ARCH}"
  local ANDROID_SYSROOT_LIB_REL="platforms/android-$API_LEVEL/arch-${ANDROID_ARCH}"
  if [ -d "$UNIFIED_SYSROOT" ]; then
    [ $API_LEVEL -lt 21 ] && PATCH_MMAP="void* mmap(void*, size_t, int, int, int, __kernel_off_t);"
    ANDROID_SYSROOT_REL=sysroot
    EXTRA_CFLAGS="$EXTRA_CFLAGS -D__ANDROID_API__=$API_LEVEL --sysroot \$NDK_ROOT/$ANDROID_SYSROOT_REL"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS --sysroot \$NDK_ROOT/$ANDROID_SYSROOT_LIB_REL" # linker need crt objects in platform-$API_LEVEL dir, must set the dir as sysroot. but --sysroot in extra-ldflags comes before configure --sysroot= and has no effect
    if [ "$USE_TOOLCHAIN" = "clang" ]; then
      EXTRA_CFLAGS="$EXTRA_CFLAGS -iwithsysroot /usr/include/$ANDROID_HEADER_TRIPLE"
    else
      EXTRA_CFLAGS="$EXTRA_CFLAGS -isystem=/usr/include/$ANDROID_HEADER_TRIPLE"
    fi
  else
    ANDROID_SYSROOT_REL=${ANDROID_SYSROOT_LIB_REL}
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --sysroot=\$NDK_ROOT/$ANDROID_SYSROOT_REL"
  fi
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --target-os=android --arch=${FFARCH} --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
  if [ "$USE_TOOLCHAIN" = "clang" ]; then
    enable_lto=false # clang -flto will generate llvm ir bitcode instead of object file. TODO: ndk-r14 supports clang lto
    TOOLCHAIN_OPT="$TOOLCHAIN_OPT --cc=clang"
    EXTRA_CFLAGS="$EXTRA_CFLAGS $CLANG_FLAGS"
    EXTRA_LDFLAGS="$EXTRA_LDFLAGS $CLANG_FLAGS" # -Qunused-arguments is added by ffmpeg configure
  else
    if $enable_lto; then
      if [ $FORCE_LTO ]; then
        TOOLCHAIN_OPT="$TOOLCHAIN_OPT --ar=${CROSS_PREFIX}gcc-ar --ranlib=${CROSS_PREFIX}gcc-ranlib"
      fi
    fi
  fi
  #test -d $ANDROID_TOOLCHAIN_DIR || $NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-$API_LEVEL --toolchain=$TOOLCHAIN --install-dir=$ANDROID_TOOLCHAIN_DIR #--system=linux-x86_64
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldexeflags=\"-Wl,--gc-sections -Wl,-z,nocopyreloc -pie -fPIE\""
  INSTALL_DIR=sdk-android-${1:-${ANDROID_ARCH}}-${USE_TOOLCHAIN:-gcc}
  enable_opt jni mediacodec
  mkdir -p $THIS_DIR/build_$INSTALL_DIR
  cat>$THIS_DIR/build_$INSTALL_DIR/.env.sh<<EOF
export PATH=$ANDROID_TOOLCHAIN_DIR/bin:$ANDROID_LLVM_DIR/bin:$PATH
EOF
}
#  --toolchain=hardened : https://wiki.debian.org/Hardening

# TODO: Security framework
setup_ios_env() {
  ENC_OPT=$ENC_OPT_MOBILE
  MUX_OPT=$MUX_OPT_MOBILE
  enable_opt videotoolbox
  LIB_OPT= #static only
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
  $enable_bitcode && echo "Bitcode is enabled by default. set 'BITCODE=false' to disable"
# http://iossupportmatrix.com
  local ios_min=6.0
  local SYSROOT_SDK=iphoneos
  local VER_OS=iphoneos
  local BITCODE_FLAGS=
  local ios5_lib_dir=
  if [ "${IOS_ARCH:0:3}" == "arm" ]; then
    $enable_bitcode && BITCODE_FLAGS="-fembed-bitcode"
    if [ "${IOS_ARCH:3:2}" == "64" ]; then
      ios_min=7.0
    else
      # armv7 since 3.2, but ios10 sdk does not have crt1.o/crt1.3.1.o, use 6.0 is ok. but we add these files in tools/lib/ios5, so 5.0 and older is fine
      local sdk_crt1_o=`xcrun --show-sdk-path --sdk iphoneos`/usr/lib/crt1.o
      if [ -f $sdk_crt1_o -o -f $THIS_DIR/tools/lib/ios5/crt1.o ]; then
        [ -f $sdk_crt1_o ] || ios5_lib_dir=$THIS_DIR/tools/lib/ios5
        ios_min=5.0
      else
        ios_min=6.0
      fi
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
  TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --arch=$IOS_ARCH --target-os=darwin --cc=clang --sysroot=\$(xcrun --sdk $SYSROOT_SDK --show-sdk-path)"
  disable_opt programs
  EXTRA_CFLAGS="$EXTRA_CFLAGS -arch $IOS_ARCH -m${VER_OS}-version-min=$ios_ver $BITCODE_FLAGS" # -fvisibility=hidden -fvisibility-inlines-hidden"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS -arch $IOS_ARCH -m${VER_OS}-version-min=$ios_ver -Wl,-dead_strip" # -fvisibility=hidden -fvisibility-inlines-hidden" #No bitcode flags for iOS < 6.0. we always build static libs. but config test will try to create exe
  if $FFGIT; then
    patch_clock_gettime=1
    [ -d $FFSRC/ffbuild ] && patch_clock_gettime=0 # since 3.3
  else
    apple_sdk_version ">=" ios 10.0 && patch_clock_gettime=$(($FFMAJOR == 3 && $FFMINOR < 3 || $FFMAJOR < 3)) # my patch is in >3.2
  fi
  INSTALL_DIR=sdk-ios-$IOS_ARCH
  mkdir -p $THIS_DIR/build_$INSTALL_DIR
  [ -n "$ios5_lib_dir" ] && echo "export LIBRARY_PATH=$ios5_lib_dir" >$THIS_DIR/build_$INSTALL_DIR/.env.sh
}

setup_macos_env(){
  local MACOS_VER=10.7
  local MACOS_ARCH=
  if [ "${1:0:5}" == "macos" ]; then
    MACOS_VER=${1##macos}
  elif [ -n "$1" ]; then
    MACOS_ARCH=$1
    ARCH_FLAG="-arch $1"
    [ -n "$2" ] && MACOS_VER=${2##macos}
  fi
  enable_opt videotoolbox vda
  version_compare $MACOS_VER "<" 10.7 && disable_opt lzma avdevice #avfoundation is not supported on 10.6
  grep -q install-name-dir $FFSRC/configure && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --install_name_dir=@rpath"
  # 10.6: ld: warning: target OS does not support re-exporting symbol _av_gettime from libavutil/libavutil.dylib
  EXTRA_CFLAGS="$EXTRA_CFLAGS $ARCH_FLAG -mmacosx-version-min=$MACOS_VER"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS $ARCH_FLAG -mmacosx-version-min=$MACOS_VER -flat_namespace -Wl,-dead_strip -Wl,-rpath,@loader_path -Wl,-rpath,@loader_path/../Frameworks -Wl,-rpath,@loader_path/lib -Wl,-rpath,@loader_path/../lib"
  if $FFGIT; then
    patch_clock_gettime=1
    [ -d $FFSRC/ffbuild ] && patch_clock_gettime=0 # since 3.3
  else
    apple_sdk_version ">=" macos 10.12 && patch_clock_gettime=$(($FFMAJOR == 3 && $FFMINOR < 3 || $FFMAJOR < 3)) # my patch is in >3.2
  fi
  INSTALL_DIR=sdk-macOS${MACOS_VER}${MACOS_ARCH}
}

# version_compare v1 "op" v2, e.g. version_compare 10.6 "<" 10.7
version_compare(){
  local v1_major=`echo $1 |cut -d '.' -f 1`
  local v1_minor=`echo $1 |cut -d '.' -f 2`
  local v2_major=`echo $3 |cut -d '.' -f 1`
  local v2_minor=`echo $3 |cut -d '.' -f 2`
  eval return $((1-$(($(($((v1_major*100))+$v1_minor))${2}$(($((v2_major*100))+$v2_minor))))))
}

apple_sdk_version(){
  #$1: operator with "" around ("<=", "<", "==", ">", ">=")
  #$2: os name used by xcrun (ios, macos, iphoneos, macosx ...)
  #$3: version number (x.y)
  local ios=iphoneos
  local macos=macosx
  local os=${!2}
  os=${os:=$2}
  local sdk_ver=`xcrun --show-sdk-version --sdk $os`
  version_compare $sdk_ver $1 $3
}

setup_maemo_env() {
  : ${MAEMO5_SYSROOT:=/opt/QtSDK/Maemo/4.6.2/sysroots/fremantle-arm-sysroot-20.2010.36-2-slim}
  : ${MAEMO6_SYSROOT:=/opt/QtSDK/Madde/sysroots/harmattan_sysroot_10.2011.34-1_slim}
#--arch=armv7l --cpu=armv7l
#CLANG=clang
  if [ -z "$MAEMO_SYSROOT" ]; then
    test $1 = 5 && MAEMO_SYSROOT=$MAEMO5_SYSROOT || MAEMO_SYSROOT=$MAEMO6_SYSROOT
  fi
  echo "MAEMO_SYSROOT=$MAEMO_SYSROOT"
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

# TODO: clang+lld without gcc
setup_rpi_env() { # cross build using ubuntu arm-linux-gnueabihf-gcc-7 result in bus error if asm is enabled
  echo "setup_rpi_env $@"
  rpi_os=rpi
  if [ "${1:0:3}" = "rpi" ]; then
    rpi_os=$1
  else
    if [ "${1:0:5}" = "armv6" ]; then
      rpi_os=rpi
    elif [ "${1:0:5}" = "armv7" ]; then
      rpi_os=rpi2
    elif [ "${1:0:5}" = "armv8" ]; then
      rpi_os=rpi3
    fi
  fi
  local sed_bak=
  host_is Darwin && sed_bak=".bak"
  if `grep -q 'check_arm_arch 6ZK;' "$FFSRC/configure"`; then
    echo "patching armv6zk probe..."
    sed -i $sed_bak 's/\(.* \)6ZK;\(.*\)/\16KZ 6ZK;\2/' "$FFSRC/configure"
  fi
  if ! `grep -q '\-lvcos' "$FFSRC/configure"`; then
    echo "patching mmal probing..."
    sed -i $sed_bak 's/-lbcm_host/-lbcm_host -lvcos -lpthread/g' "$FFSRC/configure"
  fi
  INSTALL_DIR=sdk-$rpi_os-gcc
  : ${CROSS_PREFIX:=arm-linux-gnueabihf-}
  uname -a |grep armv && {
    echo "rpi host build"
    SYSROOT_CC=`gcc -print-sysroot`
  } || {
    echo "rpi cross build"
    TOOLCHAIN_OPT="--enable-cross-compile --cross-prefix=$CROSS_PREFIX --target-os=linux --arch=arm"
    SYSROOT_CC=`${CROSS_PREFIX}gcc -print-sysroot`
    [ -d "$SYSROOT_CC/opt/vc" ] || SYSROOT_CC=
  }
  if [ -n "$USE_TOOLCHAIN" ]; then
    # TODO: apple clang invoke ld64. --ld=${CROSS_PREFIX}ld ldflags are different from cc ld flags
    TOOLCHAIN_OPT="--cc=$USE_TOOLCHAIN $TOOLCHAIN_OPT"
    if [ "${USE_TOOLCHAIN%%-*}" = "clang" ]; then
      if [ -n "$CROSS_PREFIX" ]; then
      # TODO: add -lvcos for mmal
        TOOLCHAIN_OPT="$TOOLCHAIN_OPT --sysroot=\\\$SYSROOT" # search host by default, so sysroot is required
        CLANG_TARGET=${CROSS_PREFIX%%-}
        CLANG_TARGET=${CLANG_TARGET##*/}
        CLANG_FLAGS="-target $CLANG_TARGET" # gcc cross prefix, clang use target value to find binutils, and set host triple
        #CLANG_FLAGS="-fno-integrated-as $CLANG_FLAGS" # libswscale/arm/rgb2yuv_neon_{16,32}.o error. but using arm-linux-gnueabihf-gcc-7 asm from ubuntu results in bus error
      fi
      INSTALL_DIR=sdk-$rpi_os-clang
    fi
  fi
  : ${SYSROOT:=${SYSROOT_CC}}
  USER_OPT="--enable-omx-rpi --enable-mmal $USER_OPT"
  # https://github.com/carlonluca/pot/blob/master/piomxtextures_tools/compile_ffmpeg.sh
  # -funsafe-math-optimizations -mno-apcs-stack-check -mstructure-size-boundary=32 -mno-sched-prolog
  # not only rpi vc libs, but also gcc headers and libs in sysroot may be required by some toolchains
  #[ ! "$SYSROOT" = "$SYSROOT_CC" -a -n "$SYSROOT" ] && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --sysroot=\$SYSROOT"
  #COMMON_FLAGS='-isystem=/opt/vc/include -isystem=/opt/vc/include/IL'
  #COMMOM_FLAGS='-isystem\$SYSROOT/opt/vc/include -isystem\$SYSROOT/opt/vc/include/IL'
  # armv6zk, armv6kz, armv6z: https://reviews.llvm.org/D14568
  EXTRA_CFLAGS_rpi="-march=armv6zk -mtune=arm1176jzf-s -mfpu=vfp" # no thumb support. armv6kz is not supported by some compilers, but zk is.
  EXTRA_CFLAGS_rpi2="-march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -mthumb" # -mthumb-interwork vfpv3-d16"
  EXTRA_CFLAGS_rpi3="-march=armv8-a -mtune=cortex-a53 -mfpu=crypto-neon-fp-armv8"
  eval EXTRA_CFLAGS_RPI='${EXTRA_CFLAGS_'$rpi_os'}'
  EXTRA_CFLAGS="$CLANG_FLAGS $EXTRA_CFLAGS_RPI -mfloat-abi=hard -isystem\\\$SYSROOT/opt/vc/include -isystem\\\$SYSROOT/opt/vc/include/IL $EXTRA_CFLAGS"
  EXTRA_LDFLAGS="$CLANG_FLAGS -L\\\$SYSROOT/opt/vc/lib $EXTRA_LDFLAGS"
  #-lrt: clock_gettime in glibc2.17
  [ "`${CROSS_PREFIX}gcc -print-file-name=librt.so`" = "librt.so" ] || EXTRA_LDFLAGS="$EXTRA_LDFLAGS -lrt"
  test -f /bin/sh.exe || EXTRA_LDFLAGS="-Wl,-rpath-link,\\\$SYSROOT/opt/vc/lib $EXTRA_LDFLAGS"
}

# 1 target os & 1 target arch
config1(){
  local TAGET_FLAG=$1
  local TAGET_ARCH_FLAG=$2
  local EXTRA_LDFLAGS=$EXTRA_LDFLAGS
  local EXTRA_CFLAGS=$EXTRA_CFLAGS
  local FEATURE_OPT=$FEATURE_OPT
  local TOOLCHAIN_OPT=$TOOLCHAIN_OPT
  local LIB_OPT=$LIB_OPT
  local INSTALL_DIR=sdk
  local patch_clock_gettime=0
  local enable_pic=true
  local enable_lto=true
  add_librt(){
  # clock_gettime in librt instead of glibc>=2.17
    grep -q "LIBRT" $FFSRC/configure && {
      # TODO: cc test
      host_is Linux && ! target_is android && ! echo $EXTRALIBS |grep -q '\-lrt' && ! echo $EXTRA_LDFLAGS |grep -q '\-lrt' && EXTRALIBS="$EXTRALIBS -lrt"
    }
  }
  case $1 in
    android)    setup_android_env $TAGET_ARCH_FLAG ;;
    ios*)       setup_ios_env $TAGET_ARCH_FLAG $1 ;;
    macos*)     setup_macos_env $TAGET_ARCH_FLAG $1 ;;
    mingw*)     setup_mingw_env $TAGET_ARCH_FLAG ;;
    vc)         setup_vc_desktop_env ;;
    winstore|winpc|winphone|winrt) setup_winrt_env ;;
    maemo*)     setup_maemo_env ${1##maemo} ;;
    rpi*|raspberry*) add_elf_flags && setup_rpi_env $TAGET_ARCH_FLAG $1 ;;
    x86)
      add_elf_flags
      add_librt
      if [ "`uname -m`" = "x86_64" ]; then
        #TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-cross-compile --target-os=$(tolower $(uname -s)) --arch=x86"
        EXTRA_LDFLAGS="$EXTRA_LDFLAGS -m32"
        EXTRA_CFLAGS="$EXTRA_CFLAGS -m32"
        INSTALL_DIR=sdk-x86
      fi
      ;;
    *) # assume host build. use "") ?
      : ${VC_BUILD:=false} #global is fine because no parallel configure now
      if $VC_BUILD; then
        setup_vc_env
      elif host_is MinGW || host_is MSYS; then
        setup_mingw_env
      elif host_is Linux; then
        add_elf_flags
        if [ -c /dev/vchiq ]; then
          setup_rpi_env armv6zk rpi
        else
          enable_libmfx
          enable_opt vaapi vdpau
        fi
        add_librt
      elif host_is Darwin; then
        setup_macos_env
      elif host_is Sailfish; then
        echo "Build in Sailfish SDK"
        INSTALL_DIR=sdk-sailfish
      fi
      ;;
  esac

  if $enable_lto; then
    if [ ! $FORCE_LTO ]; then
      echo "lto is disabled when build static libs to get better compatibility"
    else
      echo "lto is enabled"
      TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-lto"
    fi
  fi
  $enable_pic && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --enable-pic"
  EXTRA_CFLAGS=$(trim2 $EXTRA_CFLAGS)
  EXTRA_LDFLAGS=$(trim2 $EXTRA_LDFLAGS)
  EXTRALIBS=$(trim2 $EXTRALIBS)
  test -n "$EXTRA_CFLAGS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-cflags=\"$EXTRA_CFLAGS\""
  test -n "$EXTRA_LDFLAGS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-ldflags=\"$EXTRA_LDFLAGS\""
  test -n "$EXTRALIBS" && TOOLCHAIN_OPT="$TOOLCHAIN_OPT --extra-libs=\"$EXTRALIBS\""
  echo INSTALL_DIR: $INSTALL_DIR
  is_libav || FEATURE_OPT="$FEATURE_OPT --enable-avresample --disable-postproc"
  local CONFIGURE="configure --extra-version=QtAV --disable-doc ${DEBUG_OPT} $LIB_OPT --enable-runtime-cpudetect $FEATURE_OPT $TOOLCHAIN_OPT $USER_OPT"
  : ${NO_ENC=false}
  if ! $NO_ENC && [ -n "$ENC_OPT" ]; then
    CONFIGURE="$CONFIGURE $ENC_OPT $MUX_OPT"
  fi
  CONFIGURE=`trim2 $CONFIGURE`
  # http://ffmpeg.org/platform.html
  # static: --enable-pic --extra-ldflags="-Wl,-Bsymbolic" --extra-ldexeflags="-pie"

  mkdir -p build_$INSTALL_DIR
  cd build_$INSTALL_DIR
  echo $CONFIGURE |tee config-new.txt
  echo $FFVERSION_FULL >>config-new.txt
  local reconf=true
  if diff -NrubB config{-new,}.txt >/dev/null; then
    [ -f config.h ] && echo configuration does not change. skip configure && reconf=false
  fi
  if $reconf; then
    [ -f .env.sh ] && . .env.sh && cat .env.sh
    echo configuration changes
    time eval $CONFIGURE
    if $VC_BUILD && [ ${VisualStudioVersion:0:2} -gt 14 ] && `echo $LANG |grep -q zh`; then  # check ffmpeg version?
      iconv -t "UTF-8" -f "GBK" config.h > config-utf8.h
      cp -f config{-utf8,}.h
    fi
  fi
  if [ $? -eq 0 ]; then
    echo $CONFIGURE >config.txt
    echo $FFVERSION_FULL >>config.txt
    sed_bak=
    host_is darwin && sed_bak=".bak"
    if [ $patch_clock_gettime == 1 ]; then
      # modify only if HAVE_CLOCK_GETTIME is 1 to avoid rebuild
      if grep 'HAVE_CLOCK_GETTIME 1' config.h; then
        echo patching clock_gettime...
        sed -i $sed_bak 's/\(.*HAVE_CLOCK_GETTIME\).*/\1 0/g' config.h
      fi
    fi
    CONFIG_MAK=config.mak
    [ -f $CONFIG_MAK ] || CONFIG_MAK=ffbuild/config.mak
    [ -f $CONFIG_MAK ] || CONFIG_MAK=avbuild/config.mak
    host_is darwin && {
      echo "patching weak frameworks for old macOS/iOS"
      sed -i $sed_bak 's/-framework VideoToolbox/-weak_framework VideoToolbox/g' $CONFIG_MAK
      sed -i $sed_bak 's/-framework CoreMedia/-weak_framework CoreMedia/g' $CONFIG_MAK
    }
    local MAX_SLICES=`grep '#define MAX_SLICES' $FFSRC/libavcodec/h264dec.h 2>/dev/null`
    if [ -n "$MAX_SLICES" ]; then
      MAX_SLICES=`echo $MAX_SLICES |cut -d ' ' -f 3`
      if [ "$MAX_SLICES" -lt 64 ]; then
        echo "patching MAX_SLICES..."
        sed -i $sed_bak 's/\(#define MAX_SLICES\) .*/\1 64/' $FFSRC/libavcodec/h264dec.h
      fi
    fi
    if $VC_BUILD; then # check ffmpeg version?
      # ffmpeg.c includes compat/atomics/win32/stdatomic.h which includes winsock.h (from windows.h), os_support.h includes winsock2.h later and then have duplicated definations. winsock2,h defines _WINSOCKAPI_ to prevent inclusion of winsock.h in windows.h
      if ! `grep -q WINSOCK_PATCHED $FFSRC_TOOLS/ffmpeg.c`; then
        sed -i '/#include "config.h"/a #include "libavformat/os_support.h"  \/\/WINSOCK_PATCHED' $FFSRC_TOOLS/ffmpeg.c
      fi
      if ! `grep -q SETDLLDIRECTORY_PATCHED $FFSRC_TOOLS/cmdutils.c`; then
        sed -i '/SetDllDirectory("")/i #if (_WIN32_WINNT+0) >= 0x0502  \/\/SETDLLDIRECTORY_PATCHED' $FFSRC_TOOLS/cmdutils.c
        sed -i '/SetDllDirectory("")/a #endif' $FFSRC_TOOLS/cmdutils.c
      fi
    fi
    if [ -n "$PATCH_MMAP" ] && `grep -q 'HAVE_MMAP 1' config.h` ; then
      #sed -i $sed_bak "/#define FFMPEG_CONFIG_H/a\\
      #$PATCH_MMAP \/\*MMAP_PATCHED\*\/\\
      #" config.h
      sed -i $sed_bak 's/\(#define HAVE_MMAP\) .*/\1 0/' config.h
    fi
  else
    tail config.log || tail avbuild/config.log #libav moves config.log to avbuild dir
    exit 1
  fi
  touch $THIS_DIR/.dir/$INSTALL_DIR
}

build1(){
  if diff -NrubB config{-new,}.txt >/dev/null; then
    echo configuration ok
  else
    echo configure was not finished
    exit 1
  fi
  [ -f .env.sh ] && . .env.sh
  ## https://github.com/ninja-build/ninja/pull/1224
  time (make -j`getconf _NPROCESSORS_ONLN` install prefix="$THIS_DIR/$INSTALL_DIR" && cp -af config.txt $THIS_DIR/$INSTALL_DIR)
  [ $? -eq 0 ] || exit 2
  cd $THIS_DIR/$INSTALL_DIR
  echo "https://github.com/wang-bin/avbuild" > README.txt
  if [ -f bin/avutil.lib ]; then
    mv bin/*.lib lib
  fi
}

build_all(){
  local os=`tolower $1`
  local USE_TOOLCHAIN=$USE_TOOLCHAIN
  [ -z "$os" ] && {
    config1 $@
  } || {
    local archs=($2)
    [ -z "$archs" ] && {
      echo ">>>>>no arch is set. setting default archs..."
      [ "${os:0:3}" == "ios" ] && archs=(armv7 arm64 x86 x86_64)
      [ "$os" == "android" ] && archs=(armv5 armv7 arm64 x86)
      [ "${os:0:3}" == "rpi" -o "${os:0:9}" == "raspberry" ] && archs=(armv6zk armv7-a)
      #[ "${os:0:5}" == "macos" ] && archs=(x86_64 i386)
    }
    echo ">>>>>archs: ${archs[@]}"
    [ -z "$archs" ] && {
      config1 $os
    } || {
      local CONFIG_JOBS=()
      USE_TOOLCHAIN0=$USE_TOOLCHAIN
      for arch in ${archs[@]}; do
        if [ "${arch##*-}" == "clang" -o "${arch##*-}" == "gcc" ]; then
          USE_TOOLCHAIN=${arch##*-}
          arch=${arch%-*}
        else
          USE_TOOLCHAIN=$USE_TOOLCHAIN0
          CC_WITH_SUFFIX="${arch##*_}"
          if [ "${CC_WITH_SUFFIX%%-*}" == "clang" -o "${CC_WITH_SUFFIX%%-*}" == "gcc" ]; then
            USE_TOOLCHAIN=$CC_WITH_SUFFIX
            arch=${arch%_*}
          else
            USE_TOOLCHAIN=$USE_TOOLCHAIN0
          fi
        fi
        CONFIG_JOBS=(${CONFIG_JOBS[@]} %$((${#CONFIG_JOBS[@]}+1)))
        config1 $os $arch &
      done
      [ ${#CONFIG_JOBS[@]} -gt 0 ] && {
        echo "waiting for all configure jobs(${#CONFIG_JOBS[@]}) finished..."
        wait ${CONFIG_JOBS[@]}
        if [ $? == 0 ]; then
          echo all configuration are finished
        else
          exit 1
        fi
      }
    }
  }
  cd $THIS_DIR
  dirs=`ls .dir`
  rm -rf .dir
  for d in $dirs; do
    cd build_$d
    local INSTALL_DIR=$d
    echo building $d...
    build1
    cd $THIS_DIR
  done
  make_universal $os "$dirs"
}

make_universal()
{
  local os=$1
  local dirs=($2)
  [ -z "$dirs" ] && return 0
  if [ "${os:0:3}" == ios ]; then
    if [ ${#dirs[@]} -le 1 ]; then
      return 0
    fi
    local OUT_DIR=sdk-$os
    rm -rf $OUT_DIR
    cd $THIS_DIR
    mkdir -p $OUT_DIR/lib
    cp -af ${dirs[0]}/include $OUT_DIR
    for a in libavutil libavformat libavcodec libavfilter libavresample libavdevice libswscale libswresample; do
      libs=
      for d in ${dirs[@]}; do
        [ -f $d/lib/${a}.a ] && libs="$libs $d/lib/${a}.a"
      done
      echo "lipo -create $libs -o $OUT_DIR/lib/${a}.a"
      test -n "$libs" && {
        lipo -create $libs -o $OUT_DIR/lib/${a}.a
        lipo -info $OUT_DIR/lib/${a}.a
      }
    done
    cat build_sdk-${os}-*/config.txt >$OUT_DIR/config.txt
    echo "https://github.com/wang-bin/avbuild" >$OUT_DIR/README.txt
    rm -rf ${dirs[@]}
  elif [ "$os" == "android" ]; then
    rm -rf sdk-$os-{gcc,clang}
    for d in ${dirs[@]}; do
      USE_TOOLCHAIN=${d##*-}
      [ ! "$USE_TOOLCHAIN" == "gcc" -a ! "$USE_TOOLCHAIN" == "clang" ] && USE_TOOLCHAIN=gcc
      OUT_DIR=sdk-$os-${USE_TOOLCHAIN}
      arch=${d%-*}
      arch=${arch#sdk-$os-}
      arch=$(android_arch $arch)

      mkdir -p $OUT_DIR/lib
      cp -af $d/include $OUT_DIR
      cp -af $d/lib $OUT_DIR/lib/$arch
      cat $d/config.txt >$OUT_DIR/config-$arch.txt
      echo "https://github.com/wang-bin/avbuild" >$OUT_DIR/README.txt
      rm -rf $d
    done
  fi
}
mkdir -p .dir

build_all "$@"
# --enable-openssl  --enable-hardcoded-tables  --enable-librtmp --enable-zlib
echo ${SECONDS}s elapsed
