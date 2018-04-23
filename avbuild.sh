#!/bin/bash
# TODO: -flto=nb_cpus. lto with static build (except android)
# Unify gcc/clang(elf?) flags(like android): -Wl,-z,now -Wl,-z,-relro -Bsymbolic ...
# https://wiki.debian.org/Hardening#DEB_BUILD_HARDENING_RELRO_.28ld_-z_relro.29
# onecore for store apps
# iosurface
# apple: remove opengl properties
# push patchs to ff repo.
# TODO: os arch-cc(e.g. winxp x86-gcc, winstore10 x86, win10 x64-clang, gcc is mingw or cygwin etc. depending on host env)
# lld supports win res files? https://github.com/llvm-mirror/lld/blob/master/docs/windows_support.rst
# clang for win lower case: Windows.h WinBase.h WinDef.h
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa383751(v=vs.85).aspx
# ios: -fomit-frame-pointer  is not supported for target 'armv7'. check_cflags -Werror
# TODO: link warning as error when checking ld flags. vc/lld-link: -WX
# TODO: cc_flags, linker_flags(linker only), os_flags, os_cc_flags, os_linker_flags, cc_linker_flags+=$(prepend_Wl linker_flags)
# remove -Wl, if LD_IS_LLD
# TODO: dumpbin=>llvm-nm, dlltool=>llvm-dlltool, winres=>llvm-rc  https://github.com/mstorsjo/llvm-mingw/blob/master/Dockerfile
#set -x
echo
echo "FFmpeg build tool for all platforms. Author: wbsecg1@gmail.com 2013-2018"
echo "https://github.com/wang-bin/avbuild"

THIS_NAME=${0##*/}
THIS_DIR=$PWD
PLATFORMS="ios|android|rpi|vc|x86|winstore|winpc|winphone|mingw64"
echo "Usage:"
test -d $PWD/ffmpeg || echo "  export FFSRC=/path/to/ffmpeg"
cat<<HELP
./$THIS_NAME [target_platform [target_architecture[-clang*/gcc*]]]
target_platform can be: ${PLATFORMS}
target_architecture can be:
 ios[x.y]| android[x]|  mingw   |  rpi
         |   armv5   |          | armv6
  armv7  |   armv7   |          | armv7
  arm64  |   arm64   |          | armv8
x86/i366 |  x86/i686 | x86/i686 |
 x86_64  |   x86_64  |  x86_64  |
Build for host if no parameter is set.
Use a shortcut in winstore to build for WinRT/WinStore/MSVC target.
Environment vars: USE_TOOLCHAIN(clang, gcc etc.), USE_LD(clang, lld etc.), USER_OPT, ANDROID_NDK, SYSROOT  
config.sh and config-${target_platform}.sh is automatically included. config-lite.sh is for building smaller libraries.
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

export PATH_EXTRA="$PWD/tools/gas-preprocessor"
export PATH=$PWD/tools/gas-preprocessor:$PATH
if [ -f "$PWD/tools/nv-codec-headers/ffnvcodec.pc.in" ]; then
  sed 's/\(prefix=\).*/\1\${pcfiledir\}/' tools/nv-codec-headers/ffnvcodec.pc.in >tools/nv-codec-headers/ffnvcodec.pc
  export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PWD/tools/nv-codec-headers
fi

echo FFSRC=$FFSRC
[ -f $FFSRC/configure ] && {
  cd $FFSRC
  export PATH=$PWD:$PATH # convert win path to unix path
  export PATH_EXTRA="$PWD:$PATH_EXTRA"
  cd -
  echo "PATH: $PATH"
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
  [ -d "$FFSRC_TOOLS" ] || FFSRC_TOOLS=$FFSRC
fi
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
    grep -q "\-\-enable\-$OPT" $FFSRC/configure && FEATURE_OPT="--enable-$OPT $FEATURE_OPT" # prepend to support override
  done
}

disable_opt() {
  # grep -m1
  for OPT in $@; do
    grep -q "\-\-disable\-$OPT" $FFSRC/configure && FEATURE_OPT="--disable-$OPT $FEATURE_OPT" # prepend to support override
  done
}

enable_libmfx(){ # TODO: which pkg-config to use for cross build
  pkg-config --libs libmfx && enable_opt libmfx
}

enable_opt hwaccels

add_elf_flags() {
  # -Wl,-z,noexecstack -Wl,--as-needed is added by configure
  EXTRA_CFLAGS+=" -Wa,--noexecstack -fdata-sections -ffunction-sections -fstack-protector-strong" # TODO: check -fstack-protector-strong
  EXTRA_LDFLAGS+=" -Wl,--gc-sections" # -Wl,-z,relro -Wl,-z,now
  # rpath
}

if [ -n "$PKG_CONFIG_PATH_MFX" -a -d "$PKG_CONFIG_PATH_MFX" ]; then
  host_is MinGW || host_is MSYS || export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PKG_CONFIG_PATH_MFX
fi

sed_bak=
host_is darwin && sed_bak=".bak"

CFLAG_IWITHSYSROOT_GCC="-isystem=" # not work for win dir
CFLAG_IWITHSYSROOT_CLANG="-iwithsysroot "
CFLAGS_CLANG=
LFLAGS_CLANG=
CFLAGS_GCC=
LFLAGS_GCC=
CFLAG_IWITHSYSROOT=$CFLAG_IWITHSYSROOT_GCC
IS_CLANG=false
IS_APPLE_CLANG=false
IS_CLANG_CL=false
LD_IS_LLD=false
HAVE_LLD=false
LLVM_AR=llvm-ar
LLVM_NM=llvm-nm
LLVM_RANLIB=llvm-ranlib

use_clang() {
  if [ -n "$CROSS_PREFIX" ]; then # TODO: "$CROSS_PREFIX" != $TARGET_TRIPLE
    CLANG_TARGET=${CROSS_PREFIX%%-}
    CLANG_TARGET=${CLANG_TARGET##*/}
    CLANG_FLAGS="--target=$CLANG_TARGET" # apple clang uses -arch, but also supports -target. gcc cross prefix, clang use target value to find binutils, and set host triple
    #CLANG_FLAGS="-fno-integrated-as $CLANG_FLAGS" # libswscale/arm/rgb2yuv_neon_{16,32}.o error. but using arm-linux-gnueabihf-gcc-7 asm from ubuntu results in bus error
  fi
  # TODO: add clang c/ld flags
}

probe_cc() {
  local cc=$1
  local flags=$2
  $cc -dM -E -</dev/null |grep -q __clang__ && IS_CLANG=true
  $cc -dM -E -</dev/null |grep -q __apple_build_version__ && IS_APPLE_CLANG=true
  $IS_CLANG && {
    CFLAG_IWITHSYSROOT=$CFLAG_IWITHSYSROOT_CLANG
    # FIXME: requires flavor for lld-link
    LLD=$($USE_TOOLCHAIN -print-prog-name=lld)
    $LLD -flavor gnu -v >/dev/null && HAVE_LLD=true
  }
  $IS_CLANG_CL && HAVE_LLD=true
  $IS_APPLE_CLANG && [ -f /usr/local/opt/llvm/bin/lld ] && HAVE_LLD=true
  echo "compiler is clang: $IS_CLANG, apple clang: $IS_APPLE_CLANG, have lld: $HAVE_LLD"
}

setup_cc() {
  probe_cc $@
  $IS_CLANG && use_clang
  TOOLCHAIN_OPT+=" --cc=$USE_TOOLCHAIN"
}

use_llvm_binutils() {
  # use llvm-ar/ranlib, host ar/ranlib may not work for non-mac target(e.g. macOS)
  local clang_dir=${USE_TOOLCHAIN%clang*}
  local clang_name=${USE_TOOLCHAIN##*/}
  local clang=$USE_TOOLCHAIN
  local CLANG_FALLBACK=clang-6.0
  $IS_APPLE_CLANG && CLANG_FALLBACK=/usr/local/opt/llvm/bin/clang
  which "`$clang -print-prog-name=llvm-ar`" &>/dev/null || clang=$CLANG_FALLBACK
  which "`$clang -print-prog-name=llvm-ranlib`" &>/dev/null || clang=$CLANG_FALLBACK
  which "$LLVM_AR" &>/dev/null || LLVM_AR="\$($clang -print-prog-name=llvm-ar)" #$clang_dir${clang_name/clang/llvm-ar}
  which "$LLVM_NM" &>/dev/null || LLVM_NM="\$($clang -print-prog-name=llvm-nm)" #$clang_dir${clang_name/clang/llvm-ar}
  which "$LLVM_RANLIB" &>/dev/null || LLVM_RANLIB="\$($clang -print-prog-name=llvm-ranlib)" #$clang_dir${clang_name/clang/llvm-ranlib}
  #EXTRA_LDFLAGS+=" -nodefaultlibs"; EXTRALIBS+=" -lc -lgcc_s"
  # TODO: apple clang invoke ld64. --ld=${CROSS_PREFIX}ld ldflags are different from cc ld flags
  TOOLCHAIN_OPT="--ar=$LLVM_AR --nm=$LLVM_NM --ranlib=$LLVM_RANLIB $TOOLCHAIN_OPT"
}

use_lld() {
  echo "using (clang)lld as linker..."
  $IS_APPLE_CLANG && : ${USE_LD:="/usr/local/opt/llvm/bin/clang"}
  [[ "${USE_LD##*/}" == *lld* ]] && LD_IS_LLD=true
  # -flavor is passed in arguments and must be the 1st argument. configure will prepend flags before extra-ldflags.
  # apple clang+lld can build for non-apple targets
  [ -n "$USE_LD" ] && TOOLCHAIN_OPT+=" --ld=\"$USE_LD $@\"" # TODO: what if host strip does not supported target? -s may be not supported, e.g. -flavor darwin
  $LD_IS_LLD || {
    FUSE_LD="${USE_LD:=lld}"
    [[ "${USE_LD##*/}" == *lld* ]] || FUSE_LD=lld # not lld or lld-link
    EXTRA_LDFLAGS="-s -fuse-ld=$FUSE_LD $EXTRA_LDFLAGS" # -s: strip flag passing to lld
    USER_OPT="--disable-stripping $USER_OPT"; # disable strip command because cross gcc may be not installed
  }
}

# or simply call "${CFLAG_IWITHSYSROOT}{dir1,dir2,...}"
include_with_sysroot() {
  local dirs=($@)
  EXTRA_CFLAGS+=" ${dirs[@]/#/${CFLAG_IWITHSYSROOT}}"
}
# compat for windows path (e.g. android gcc toolchain can not recognize dir in -isystem=), assume clang is fine(to be tested)
include_with_sysroot_compat() {
  $IS_CLANG && {
    include_with_sysroot $@
    return 0
  }
  local dirs=($@)
  EXTRA_CFLAGS+=" ${dirs[@]/#/-isystem \$SYSROOT}"
}

check_cross_build() {
  IS_CROSS=
  IS_HOST=
  IS_NATIVE=
}
# warnings are used by ffmpeg developer, some are enabled by configure: -Wl,--warn-shared-textrel

setup_win(){
  : ${USE_TOOLCHAIN:=cl}
  probe_cc $USE_TOOLCHAIN
  $IS_CLANG && setup_win_clang $@ || setup_vc_env $@
}

setup_win_clang(){ # TODO: ./avbuild.sh win|windesktop|winstore|winrt x86-clang. TODO: clang-cl, see putty
# -imsvc: add msvc system header path
  #LIB_OPT+=" --disable-static"
  : ${USE_TOOLCHAIN:=clang}
  setup_cc $USE_TOOLCHAIN
  USE_LD=$($USE_TOOLCHAIN -print-prog-name=lld-link) use_lld # lld 6.0 fixes undefined __enclave_config in msvcrt14.12. `lld -flavor link` just warns --version-script and results in link error
  use_llvm_binutils
  #use_lld # --target=i386-pc-windows-msvc19.13.0 -fuse-ld=lld: must use with -Wl,
  enable_libmfx
  enable_opt dxva2
  WIN_VER="0x0600"
  : ${Platform:=$arch}
  if [ "${platform:0:3}" = "arm" ]; then
    arch=arm
  elif [ -z "${Platform/*64/}" ]; then
    arch=x86_64
  else
    arch=x86
    target_tripple_arch=i386
  fi
  : ${target_tripple_arch:=$arch}
  # environment var LIB is used by lld-link, in windows style, i.e. export LIB=dir1;dir2;...
  # makedef: define env AR=llvm-ar, NM=llvm-nm
  # --windres=rc option is broken and not recognized
  TOOLCHAIN_OPT+=" --enable-cross-compile --arch=$arch --target-os=win32"
  [ -n "$WIN_VER_LD" ] && TOOLCHAIN_OPT+=" --extra-ldexeflags='-SUBSYSTEM:CONSOLE,$WIN_VER_LD'"
  EXTRA_CFLAGS+=" --target=${target_tripple_arch}-pc-windows-msvc19.13.0 -DWIN32 -D_WIN32 -D_WIN32_WINNT=$WIN_VER -Wno-nonportable-include-path -Wno-deprecated-declarations" # -Wno-deprecated-declarations: avoid clang crash
  EXTRA_LDFLAGS+=" -OPT:REF -SUBSYSTEM:CONSOLE -NODEFAULTLIB:libcmt -DEFAULTLIB:msvcrt"
  EXTRALIBS+=" oldnames.lib" # fdopen, tempnam, close used in file_open.c
  INSTALL_DIR="sdk-win-$arch-clang"

# vcrt and win sdk dirs
  win10inc=(shared ucrt um winrt)
  win10inc=(${win10inc[@]/#/$WindowsSdkDir/Include/$WindowsSDKVersion/})
  IFS=\; eval 'INCLUDE="${win10inc[*]}"'

  mkdir -p $THIS_DIR/build_$INSTALL_DIR
  cat > "$THIS_DIR/build_$INSTALL_DIR/.env.sh" <<EOF
export INCLUDE="$VCDIR/include;$INCLUDE"
export LIB="$VCDIR/lib/${arch/86_/};$WindowsSdkDir/Lib/$WindowsSDKVersion/ucrt/${arch/86_/};$WindowsSdkDir/Lib/$WindowsSDKVersion/um/${arch/86_/}"
export AR=$LLVM_AR
export NM=$LLVM_NM
export V=1 # FFmpeg BUG: AR is overriden in common.mak and becomes an invalid command in makedef(@printf is works in makefiles but not sh scripts)
EOF
}

setup_vc_env() {
  local arch=$1
  local osver=$2
  echo Call "set MSYS2_PATH_TYPE=inherit" before msys2 sh.exe if cl.exe is not found!
  enable_lto=false # ffmpeg requires DCE, while vc with LTCG (-GL) does not support DCE
  LIB_OPT+=" --disable-static"
  # dylink crt
  EXTRA_CFLAGS+=" -MD"
  EXTRA_LDFLAGS+=" -OPT:REF -SUBSYSTEM:CONSOLE -NODEFAULTLIB:libcmt" #-NODEFAULTLIB:libcmt -winmd?
  TOOLCHAIN_OPT+=" --toolchain=msvc"
  VS_VER=${VisualStudioVersion:0:2}
  : ${Platform:=x86} #Platform is empty(native) or x86(cross using 64bit toolchain)
  Platform=${arch:-${Platform}} # arch is set, but may be null,  so :-
  local platform=$(tolower $Platform)
  echo "VS version: $VS_VER, platform: $Platform" # Platform is from vsvarsall.bat

  [ -n "$PKG_CONFIG_PATH_MFX" ] && PKG_CONFIG_PATH_MFX_UNIX=$(cygpath -u "$PKG_CONFIG_PATH_MFX")
  [ -d "$PKG_CONFIG_PATH_MFX_UNIX" ] || PKG_CONFIG_PATH_MFX_UNIX=${PKG_CONFIG_PATH_MFX_UNIX/\/lib\/pkgconfig/$Platform\/lib\/pkgconfig}
  export PKG_CONFIG_PATH_MFX=$PKG_CONFIG_PATH_MFX_UNIX
  [ -d "$PKG_CONFIG_PATH_MFX_UNIX" ] && export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PKG_CONFIG_PATH_MFX_UNIX"
  FAMILY=
  WIN_VER=
  if $WINRT; then
    [ -z "$osver" ] && osver=winrt
    setup_vc_winrt_env $arch
  else
    [ -z "$osver" ] && osver=win
    FAMILY=_DESKTOP
    setup_vc_desktop_env $arch
  fi

  EXTRA_CFLAGS+=" -D_WIN32_WINNT=$WIN_VER" #  -DWINAPI_FAMILY=WINAPI_FAMILY${FAMILY}_APP is not required for desktop
  INSTALL_DIR="`tolower sdk-$osver-$Platform-cl${VS_CL}`"

  rm -rf $THIS_DIR/build_$INSTALL_DIR/.env.sh
  mkdir -p $THIS_DIR/build_$INSTALL_DIR
# get env vars for given arch, and export for build
  local PATH_arch=PATH_$platform
  PATH_arch=${!PATH_arch}
# LIB, LIBPATH, INCLUDE are used by vc compiler and linker only, so keep the original path style
  local LIB_arch=LIB_$platform
  LIB_arch=$(echo ${!LIB_arch} |sed 's/\\/\\\\/g;s/(/\\\(/g;s/)/\\\)/g;s/ /\\ /g;s/\;/\\\;/g')
  local LIBPATH_arch=LIBPATH_$platform
  LIBPATH_arch=$(echo ${!LIBPATH_arch} |sed 's/\\/\\\\/g;s/(/\\\(/g;s/)/\\\)/g;s/ /\\ /g;s/\;/\\\;/g')
  local INCLUDE_arch=INCLUDE_$platform
  INCLUDE_arch=$(echo ${!INCLUDE_arch} |sed 's/\\/\\\\/g;s/(/\\\(/g;s/)/\\\)/g;s/ /\\ /g;s/\;/\\\;/g')
  [ -n "$PATH_arch" ] && {
  # msvc exes are used by script, so must be converted to posix paths
    PATH_arch=$(cygpath -u "$PATH_arch" |sed 's/\([a-zA-Z]\):/\/\1/g;s/\;/:/g;s/(/\\\(/g;s/)/\\\)/g;s/ /\\ /g')
  # PATH_arch is set before bash environment, so must manually add bash paths
    echo "export PATH=$PATH_EXTRA:/usr/local/bin:/usr/bin:/bin:/opt/bin:$PATH_arch" >"$THIS_DIR/build_$INSTALL_DIR/.env.sh"
  }
  [ -n "$LIB_arch" ] && echo "export LIB=$LIB_arch" >>"$THIS_DIR/build_$INSTALL_DIR/.env.sh"
  [ -n "$LIBPATH_arch" ] && echo "export LIBPATH=$LIBPATH_arch" >>"$THIS_DIR/build_$INSTALL_DIR/.env.sh"
  [ -n "$INCLUDE_arch" ] && echo "export INCLUDE=$INCLUDE_arch" >>"$THIS_DIR/build_$INSTALL_DIR/.env.sh"
  [ -d "$PKG_CONFIG_PATH_MFX_UNIX" ] && cat >> "$THIS_DIR/build_$INSTALL_DIR/.env.sh" <<EOF
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH
EOF
}

setup_vc_desktop_env() {
# http://ffmpeg.org/platform.html#Microsoft-Visual-C_002b_002b-or-Intel-C_002b_002b-Compiler-for-Windows
  enable_libmfx
  enable_opt dxva2
  # ldflags prepends flags. extralibs appends libs and add to pkg-config
  # can not use -luser32 because extralibs will not be filter -l to .lib (ldflags_filter is not ready, ffmpeg bug)
  # TODO: check dxva2_extralibs="-luser32" in configure
  grep -q " user32 " "$FFSRC/configure" || EXTRALIBS+=" user32.lib" # ffmpeg 3.x bug: hwcontext_dxva2 GetDesktopWindow()
  if $FFGIT; then
    WIN_VER="0x0600"
  elif [ $FFMAJOR -gt 3 ]; then
    WIN_VER="0x0600"
  else
    if [ -z "${Platform/*64/}" ]; then
      WIN_VER="0x0502"
      [ $VS_VER -gt 10 ] && echo "adding windows xp compatible link flags..." && TOOLCHAIN_OPT+=" --extra-ldexeflags='-SUBSYSTEM:CONSOLE,5.02'"
    else
      WIN_VER="0x0501"
      [ $VS_VER -gt 10 ] && echo "adding windows xp compatible link flags..." && TOOLCHAIN_OPT+=" --extra-ldexeflags='-SUBSYSTEM:CONSOLE,5.01'"
    fi
  fi
}

setup_vc_winrt_env() {
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
  TOOLCHAIN_OPT+=" --enable-cross-compile --target-os=win32"
  EXTRA_LDFLAGS+=" -APPCONTAINER"
  WIN_VER="0x0A00"
  test $VS_VER -lt 14 && WIN_VER="0x0603" #FIXME: vc can support multiple target (and sdk)
  WIN10_VER_DEC=`printf "%d" 0x0A00`
  WIN81_VER_DEC=`printf "%d" 0x0603`
  WIN_VER_DEC=`printf "%d" $WIN_VER`
  local arch=x86_64 #used by configure --arch
  if [ "${platform:0:3}" = "arm" ]; then # TODO: arm64
    enable_pic=false  # TODO: ffmpeg bug, should filter out -fPIC. armasm(gas) error (unsupported option) if pic is
    type -a gas-preprocessor.pl
    ASM_OPT="--enable-thumb"
    # vc only arm64_neon.h
    [ -z "${platform/*64*/}" ] && {
      BIT=64
      TOOLCHAIN_OPT+=" --disable-pic" # arm64 pic is enabled by: enabled spic && enable_weak pic
    } || ASM_OPT+=" --cpu=armv7-a"
    which cpp &>/dev/null && {
      ASM_OPT+=" --as=armasm$BIT"
    } || {
      echo "ASM is disabled: cpp is required by gas-preprocessor but it is missing. make sure (mingw) gcc is in your PATH"
      ASM_OPT=--disable-asm
    }
    #gas-preprocessor.pl change open(INPUT, "-|", @preprocess_c_cmd) || die "Error running preprocessor"; to open(INPUT, "@preprocess_c_cmd|") || die "Error running preprocessor";
    #EXTRA_CFLAGS+=" -D__ARM_PCS_VFP" # for gcc, hard float
    EXTRA_LDFLAGS+=" -MACHINE:$Platform"
    arch="$platform"
    TOOLCHAIN_OPT+=" $ASM_OPT"
  else
    [ -z "${Platform/*64/}" ] && arch=x86_64 || arch=x86
  fi
  : ${WINPHONE:=false}
  target_is winphone && WINPHONE=true
  if $WINPHONE; then
  # export dirs (lib, include)
    FAMILY=_PHONE
    # phone ldflags only for win8.1?
    EXTRA_LDFLAGS+=" WindowsPhoneCore.lib RuntimeObject.lib PhoneAppModelHost.lib -NODEFAULTLIB:kernel32.lib -NODEFAULTLIB:ole32.lib"
  fi
  if [ $WIN_VER_DEC  -gt ${WIN81_VER_DEC} ]; then
  # store: can not use onecoreuap.lib, must use windowsapp.lib
  # uwp: can use onecoreuap.lib
    EXTRA_LDFLAGS+=" WindowsApp.lib"
  fi
  TOOLCHAIN_OPT+=" --arch=$arch"
  EXTRA_CFLAGS+=" -DWINAPI_FAMILY=WINAPI_FAMILY${FAMILY}_APP"
}

setup_mingw_env() {
  LIB_OPT+=" --disable-static"
  enable_lto=false
  local gcc=gcc
  local arch=$1
  local native_build=false # native build: use gcc instead of ${arch}-w64-mingw32-gcc
  if [ -n "$arch" ]; then
    [ -z "${arch/*64*/}" ] && BIT=64 || BIT=32
    arch=x86_$BIT
    arch=${arch/*_32/i686}
  fi
  host_is MinGW || host_is MSYS && echo "install msys2 packages: pacman -Sy --needed diffutils gawk patch pkg-config mingw-w64-i686-gcc mingw-w64-x86_64-gcc nasm yasm"
  # msys2 /usr/bin/gcc is x86_64-pc-msys
  $gcc -dumpmachine |grep -iq mingw && {
    [ -z "$arch" ] && native_build=true || {
      $gcc -dumpmachine |grep -iq "$arch" && native_build=true
    }
  }
  $native_build && { # arch is not set. probe using gcc
    $gcc -dumpmachine |grep -iq "x86_64" && BIT=64 || BIT=32
    arch=x86_$BIT
    arch=${arch/*_32/i686}
    echo "mingw $arch host native build"
  } || {
    gcc=${arch}-w64-mingw32-gcc
    host_is MinGW || host_is MSYS && {
      echo "mingw host build for $arch" # TODO: -m32/64?
      # mingw-w64-cross-gcc package has broken old mingw compilers with the same prefix, so prefer compilers in $MINGW_BIN
      TOOLCHAIN_OPT+=" --cc=$gcc --target-os=mingw$BIT" # set target os recognized by configure. msys and mingw without 32/64 are rejected by configure
      local MINGW_BIN=/mingw${BIT}/bin
      [ -d $MINGW_BIN ] && export PATH=$MINGW_BIN:$PATH
    } || {
      echo "mingw cross build for $arch"
      TOOLCHAIN_OPT+=" --enable-cross-compile --cross-prefix=${arch}-w64-mingw32- --target-os=mingw$BIT --arch=$arch"
    }
  }
  [ -n "$PKG_CONFIG_PATH_MFX" ] && PKG_CONFIG_PATH_MFX_UNIX=$(cygpath -u "$PKG_CONFIG_PATH_MFX")
  [ -d "$PKG_CONFIG_PATH_MFX_UNIX" ] || PKG_CONFIG_PATH_MFX_UNIX=${PKG_CONFIG_PATH_MFX_UNIX/\/lib\/pkgconfig/$BIT\/lib\/pkgconfig}
  export PKG_CONFIG_PATH_MFX=$PKG_CONFIG_PATH_MFX_UNIX
  [ -d "$PKG_CONFIG_PATH_MFX_UNIX" ] && export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PKG_CONFIG_PATH_MFX_UNIX"

  enable_libmfx
  enable_opt dxva2
  disable_opt iconv
  EXTRA_LDFLAGS+=" -static-libgcc -Wl,-Bstatic"
  INSTALL_DIR="${INSTALL_DIR}-mingw-x${BIT/32/86}-gcc"
  rm -rf $THIS_DIR/build_$INSTALL_DIR/.env.sh
  mkdir -p $THIS_DIR/build_$INSTALL_DIR
  [ -d "$MINGW_BIN" ] && cat>$THIS_DIR/build_$INSTALL_DIR/.env.sh<<EOF
export PATH=$MINGW_BIN:$PATH
shopt -s expand_aliases
#alias ${arch}-w64-mingw32-strip=$MINGW_BIN/strip # seems not work in sh used by ffmpeg
#alias ${arch}-w64-mingw32-nm=$MINGW_BIN/nm
EOF
  [ -d "$PKG_CONFIG_PATH_MFX_UNIX" ] && cat >> "$THIS_DIR/build_$INSTALL_DIR/.env.sh" <<EOF
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH
EOF
}

# TOOLCHAIN_OPT+=" --enable-cross-compile --cross-prefix=arm-mingw32ce- --target-os=mingw32ce --arch=arm --cpu=arm"

setup_android_env() {
  ENC_OPT=$ENC_OPT_MOBILE
  MUX_OPT=$MUX_OPT_MOBILE
  disable_opt v4l2_m2m v4l2-m2m
  local ANDROID_ARCH=${1:=arm}
  TRIPLE_ARCH=$ANDROID_ARCH
  local ANDROID_TOOLCHAIN_PREFIX="${ANDROID_ARCH}-linux-android"
  local CROSS_PREFIX=${ANDROID_TOOLCHAIN_PREFIX}-
  local FFARCH=$ANDROID_ARCH
  local API_LEVEL=${2#android}
  [ -z "$API_LEVEL" ] && API_LEVEL=14 #api9: ensure do not use log2f in libm
  local UNIFIED_SYSROOT="$NDK_ROOT/sysroot"
  [ -d "$UNIFIED_SYSROOT" ] || UNIFIED_SYSROOT=
  add_elf_flags
  EXTRA_CFLAGS+=" -ffast-math -fstrict-aliasing"
# -no-canonical-prefixes: results in "-mcpu= ", why?
  EXTRA_LDFLAGS+=" -Wl,-z,relro -Wl,-z,now"
  # TODO: clang lto in r14 (gcc?) except aarch64
  if [ -z "${ANDROID_ARCH/*86/}" ]; then
    ANDROID_ARCH=x86
    TRIPLE_ARCH=i686
    ANDROID_TOOLCHAIN_PREFIX=$ANDROID_ARCH
    CLANG_FLAGS+=" --target=i686-none-linux-android"
    # from ndk: x86 devices have stack alignment issues.
    # clang error: inline assembly requires more registers than available ("movzbl "statep"    , "ret")
    CFLAGS_GCC+=" -mstackrealign"
    enable_lto=false
  elif [ -z "${ANDROID_ARCH/x*64/}" ]; then
    [ $API_LEVEL -lt 21 ] && API_LEVEL=21
    ANDROID_ARCH=x86_64
    TRIPLE_ARCH=$ANDROID_ARCH
    ANDROID_TOOLCHAIN_PREFIX=$ANDROID_ARCH
    CLANG_FLAGS+=" --target=x86_64-none-linux-android"
    enable_lto=false
  elif [ -z "${ANDROID_ARCH/a*r*64/}" ]; then
    [ $API_LEVEL -lt 21 ] && API_LEVEL=21
    ANDROID_ARCH=arm64
    TRIPLE_ARCH=aarch64
    ANDROID_TOOLCHAIN_PREFIX=${TRIPLE_ARCH}-linux-android
    CLANG_FLAGS+=" --target=aarch64-none-linux-android"
  elif [ -z "${ANDROID_ARCH/*arm*/}" ]; then
#https://wiki.debian.org/ArmHardFloatPort/VfpComparison
    TRIPLE_ARCH=arm
    ANDROID_TOOLCHAIN_PREFIX=${TRIPLE_ARCH}-linux-androideabi
    FFARCH=arm
    if [ -z "${ANDROID_ARCH/armv5*/}" ]; then
      echo "armv5"
      TOOLCHAIN_OPT+=" --cpu=armv5te"
      CLANG_FLAGS+=" --target=armv5te-none-linux-androideabi"
: '
-mthumb error
selected processor does not support Thumb mode `itt gt
D:\msys2\tmp\ccXOcbBA.s:262: Error: instruction not supported in Thumb16 mode -- adds r3,r1,r0,lsr#31 
use armv6t2 or -mthumb-interwork: https://gcc.gnu.org/onlinedocs/gcc-4.5.3/gcc/ARM-Options.html
'
# -msoft-float == -mfloat-abi=soft https://gcc.gnu.org/onlinedocs/gcc-4.5.3/gcc/ARM-Options.html
      EXTRA_CFLAGS+=" -mtune=xscale -msoft-float" # -march=armv5te
      CFLAGS_GCC+=" -mthumb-interwork"
    else
      TOOLCHAIN_OPT+=" --enable-thumb --enable-neon"
      EXTRA_CFLAGS_FPU="-mfpu=vfpv3-d16"
      if [ -z "${ANDROID_ARCH/*neon*/}" ]; then
        enable_lto=false
        echo "neon. can not run on Marvell and nVidia"
        EXTRA_CFLAGS_FPU="-mfpu=neon"
        CFLAGS_GCC+=" -mvectorize-with-neon-quad"
      fi
      CLANG_FLAGS+=" --target=armv7-none-linux-androideabi"
      EXTRA_CFLAGS+=" -march=armv7-a -mtune=cortex-a8 -mfloat-abi=softfp $EXTRA_CFLAGS_FPU" #-mcpu= is deprecated in gcc 3, use -mtune=cortex-a8 instead
      EXTRA_LDFLAGS+=" -Wl,--fix-cortex-a8"
    fi
    ANDROID_ARCH=arm
  fi
  ANDROID_HEADER_TRIPLE=${TRIPLE_ARCH}-linux-android
  [ "$ANDROID_ARCH" == "arm" ] && ANDROID_HEADER_TRIPLE=${ANDROID_HEADER_TRIPLE}eabi
  CROSS_PREFIX=${ANDROID_HEADER_TRIPLE}-
  local TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.9
  [ -d $NDK_ROOT/toolchains/${TOOLCHAIN} ] || TOOLCHAIN=${ANDROID_TOOLCHAIN_PREFIX}-4.8
  local ANDROID_TOOLCHAIN_DIR="$NDK_ROOT/toolchains/${TOOLCHAIN}"
  gxx=`find ${ANDROID_TOOLCHAIN_DIR} -name "*g++*"` # can not use "*-gcc*": can be -gcc-ar, stdint-gcc.h
  clangxxs=(`find $NDK_ROOT/toolchains/llvm/prebuilt -name "clang++*"`) # can not be "clang*": clang-tidy
  clangxx=${clangxxs[0]}
  echo "g++: $gxx, clang++: $clangxx IS_CLANG:$IS_CLANG"
  $IS_CLANG && probe_cc $clangxx || probe_cc $gxx
  ANDROID_TOOLCHAIN_DIR=${gxx%bin*}
  local ANDROID_LLVM_DIR=${clangxx%bin*}
  echo "ANDROID_TOOLCHAIN_DIR=${ANDROID_TOOLCHAIN_DIR}"
  echo "ANDROID_LLVM_DIR=${ANDROID_LLVM_DIR}"
  ANDROID_TOOLCHAIN_DIR_REL=${ANDROID_TOOLCHAIN_DIR#$NDK_ROOT}
  LFLAGS_CLANG+=" -gcc-toolchain \$NDK_ROOT/$ANDROID_TOOLCHAIN_DIR_REL" # ld from gcc toolchain. TODO: lld?
  [ "$ANDROID_ARCH" == "arm" ] && CFLAGS_CLANG="-fno-integrated-as -gcc-toolchain \$NDK_ROOT/$ANDROID_TOOLCHAIN_DIR_REL $CFLAGS_CLANG" # Disable integrated-as for better compatibility, but need as from gcc toolchain. from ndk cmake
  local ANDROID_SYSROOT_LIB="$NDK_ROOT/platforms/android-$API_LEVEL/arch-${ANDROID_ARCH}"
  local ANDROID_SYSROOT_LIB_REL="platforms/android-$API_LEVEL/arch-${ANDROID_ARCH}"
  if [ -d "$UNIFIED_SYSROOT" ]; then
    [ $API_LEVEL -lt 21 ] && PATCH_MMAP="void* mmap(void*, size_t, int, int, int, __kernel_off_t);"
    ANDROID_SYSROOT_REL=sysroot
    SYSROOT=$NDK_ROOT/$ANDROID_SYSROOT_REL
    EXTRA_CFLAGS+=" -D__ANDROID_API__=$API_LEVEL --sysroot \$SYSROOT"
    EXTRA_LDFLAGS+=" --sysroot \$NDK_ROOT/$ANDROID_SYSROOT_LIB_REL" # linker need crt objects in platform-$API_LEVEL dir, must set the dir as sysroot. but --sysroot in extra-ldflags comes before configure --sysroot= and has no effect
    include_with_sysroot_compat /usr/include/$ANDROID_HEADER_TRIPLE
  else
    ANDROID_SYSROOT_REL=${ANDROID_SYSROOT_LIB_REL}
    TOOLCHAIN_OPT+=" --sysroot=\$NDK_ROOT/$ANDROID_SYSROOT_REL"
  fi
  TOOLCHAIN_OPT+=" --target-os=android --arch=${FFARCH} --enable-cross-compile --cross-prefix=$CROSS_PREFIX"
  if $IS_CLANG ; then
    TOOLCHAIN_OPT+=" --cc=clang"
    EXTRA_CFLAGS+=" $CFLAGS_CLANG $CLANG_FLAGS"
    $LD_IS_LLD || EXTRA_LDFLAGS+=" $LFLAGS_CLANG $CLANG_FLAGS" # -Qunused-arguments is added by ffmpeg configure
  else
    EXTRA_CFLAGS+=" $CFLAGS_GCC $GCC_FLAGS"
    EXTRA_LDFLAGS+=" $LFLAGS_GCC $GCC_FLAGS"
    if $enable_lto; then
      if [ $FORCE_LTO ]; then
        TOOLCHAIN_OPT+=" --ar=${CROSS_PREFIX}gcc-ar --ranlib=${CROSS_PREFIX}gcc-ranlib"
      fi
    fi
  fi
  #test -d $ANDROID_TOOLCHAIN_DIR || $NDK_ROOT/build/tools/make-standalone-toolchain.sh --platform=android-$API_LEVEL --toolchain=$TOOLCHAIN --install-dir=$ANDROID_TOOLCHAIN_DIR #--system=linux-x86_64
  TOOLCHAIN_OPT+=" --extra-ldexeflags=\"-Wl,--gc-sections -Wl,-z,nocopyreloc -pie -fPIE\""
  INSTALL_DIR=sdk-android-${1:-${ANDROID_ARCH}}
  $IS_CLANG && INSTALL_DIR="${INSTALL_DIR}-clang" || INSTALL_DIR="${INSTALL_DIR}-gcc"
  enable_opt jni mediacodec
  mkdir -p $THIS_DIR/build_$INSTALL_DIR
  cat>$THIS_DIR/build_$INSTALL_DIR/.env.sh<<EOF
export PATH=$ANDROID_TOOLCHAIN_DIR/bin:$ANDROID_LLVM_DIR/bin:$PATH
EOF
}
#  --toolchain=hardened : https://wiki.debian.org/Hardening

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
    TOOLCHAIN_OPT+=" --enable-thumb"
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
  TOOLCHAIN_OPT+=" --enable-cross-compile --arch=$IOS_ARCH --target-os=darwin --cc=clang --sysroot=\$(xcrun --sdk $SYSROOT_SDK --show-sdk-path)"
  disable_opt programs
  EXTRA_CFLAGS+=" -arch $IOS_ARCH -m${VER_OS}-version-min=$ios_ver $BITCODE_FLAGS" # -fvisibility=hidden -fvisibility-inlines-hidden"
  EXTRA_LDFLAGS+=" -arch $IOS_ARCH -m${VER_OS}-version-min=$ios_ver -Wl,-dead_strip" # -fvisibility=hidden -fvisibility-inlines-hidden" #No bitcode flags for iOS < 6.0. we always build static libs. but config test will try to create exe
  if $FFGIT; then
    patch_clock_gettime=1
    [ -d $FFSRC/ffbuild ] && patch_clock_gettime=0 # since 3.3
  else
    apple_sdk_version ">=" ios 10.0 && patch_clock_gettime=$(($FFMAJOR == 3 && $FFMINOR < 3 || $FFMAJOR < 3)) # my patch is in >3.2
  fi
  INSTALL_DIR=sdk-ios-$IOS_ARCH
  mkdir -p $THIS_DIR/build_$INSTALL_DIR
  [ -n "$ios5_lib_dir" ] && echo "export LIBRARY_PATH=$ios5_lib_dir" >$THIS_DIR/build_$INSTALL_DIR/.env.sh
  sed -i $sed_bak '/check_cflags -Werror=partial-availability/d' "$FFSRC/configure" # for SSL, VT
}

setup_macos_env(){
  local MACOS_VER=10.7
  local MACOS_ARCH=
  if [ "${1:0:5}" == "macos" ]; then
    MACOS_VER=${1##macos}
  elif [ "${1:0:3}" == "osx" ]; then
    MACOS_VER=${1##osx}
  elif [ -n "$1" ]; then
    MACOS_ARCH=$1
    ARCH_FLAG="-arch $1"
    [ -n "$2" ] && {
      MACOS_VER=${2##macos}
      MACOS_VER=${MACOS_VER##osx}
    }
  fi
  enable_opt videotoolbox vda
  version_compare $MACOS_VER "<" 10.7 && disable_opt lzma avdevice #avfoundation is not supported on 10.6
  grep -q install-name-dir $FFSRC/configure && TOOLCHAIN_OPT+=" --install_name_dir=@rpath"
  if $FFGIT; then
    patch_clock_gettime=1
    [ -d $FFSRC/ffbuild ] && patch_clock_gettime=0 # since 3.3
  else
    apple_sdk_version ">=" macos 10.12 && patch_clock_gettime=$(($FFMAJOR == 3 && $FFMINOR < 3 || $FFMAJOR < 3)) # my patch is in >3.2
  fi
  setup_cc ${USE_TOOLCHAIN:=clang}
  local LFLAG_PRE="-Wl,"
  local LFLAG_VERSION_MIN="-mmacosx-version-min=" # used by clang, "-macosx_version_min " is passed to ld
  [ "${USE_LD##*/}" == "lld" ] && {
    use_lld -flavor darwin
    LFLAG_PRE=
    LFLAG_VERSION_MIN="-macosx_version_min "
    EXTRA_LDFLAGS+=" -demangle -dynamic"
    EXTRA_LDSOFLAGS+=" -dylib" # via "clang -dynamiclib"
    EXTRALIBS+=" -lSystem" # from clang to ld. set -sdk_version anyversion to kill warnings
    version_compare $MACOS_VER "<" 10.8 && EXTRALIBS+=" -lcrt1.10.6.o"
  }
  $IS_APPLE_CLANG || $LD_IS_LLD || {
    TOOLCHAIN_OPT+=" --sysroot=\$(xcrun --sdk macosx --show-sdk-path)"
  }
  local rpath_dirs=(@loader_path @loader_path/../Frameworks @loader_path/lib @loader_path/../lib)
  local rpath_flags=
  [ -n "$LFLAG_PRE" ] && {
    rpath_flags=${rpath_dirs[@]/#/${LFLAG_PRE}-rpath,}
  } || {
    rpath_flags=${rpath_dirs[@]/#/-rpath }
  }
  # 10.6: ld: warning: target OS does not support re-exporting symbol _av_gettime from libavutil/libavutil.dylib
  EXTRA_CFLAGS+=" $ARCH_FLAG -mmacosx-version-min=$MACOS_VER"
  EXTRA_LDFLAGS+=" $ARCH_FLAG $LFLAG_VERSION_MIN$MACOS_VER -flat_namespace ${LFLAG_PRE}-dead_strip $rpath_flags"
  INSTALL_DIR=sdk-macOS${MACOS_VER}${MACOS_ARCH}-${USE_TOOLCHAIN##*/}
  sed -i $sed_bak '/check_cflags -Werror=partial-availability/d' "$FFSRC/configure" # for SSL, VT
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

#  : ${MAEMO5_SYSROOT:=/opt/QtSDK/Maemo/4.6.2/sysroots/fremantle-arm-sysroot-20.2010.36-2-slim}
#  : ${MAEMO6_SYSROOT:=/opt/QtSDK/Madde/sysroots/harmattan_sysroot_10.2011.34-1_slim}
# armv7l, --target=arm-none-linux-gnueabi

setup_rpi_env() { # cross build using ubuntu arm-linux-gnueabihf-gcc-7 result in bus error if asm is enabled
  add_elf_flags
  local rpi_cc=gcc
  local ARCH=${1:0:5}
  local rpi_cross=false
  if ! `grep -q 'check_arm_arch 6KZ;' "$FFSRC/configure"`; then
    echo "patching armv6zk probe..."
    sed -i $sed_bak "/then echo armv6zk/a\\
\        elif check_arm_arch 6KZ;      then echo armv6zk\\
" "$FFSRC/configure"
  fi
  if ! `grep -q '\-lvcos' "$FFSRC/configure"`; then
    echo "patching mmal probing..."
    sed -i $sed_bak 's/-lbcm_host/-lbcm_host -lvcos -lpthread/g' "$FFSRC/configure"
  fi
  if ! `grep -q MMAL_PARAMETER_ZERO_COPY "$FFSRC/libavcodec/mmaldec.c"` && [ -f "$FFSRC/libavcodec/mmaldec.c" ]; then
    cp -af patches/0002-mmal-enable-0-copy-for-egl-interop.patch "$FFSRC/tmp.patch"
    cd "$FFSRC"
    patch -p1 <"tmp.patch"
    cd -
  fi
  : ${CROSS_PREFIX:=arm-linux-gnueabihf-}
  [ -c /dev/vchiq ] && {
    echo "rpi host build"
    SYSROOT_CC=`gcc -print-sysroot`
  } || {
    rpi_cross=true
    echo "rpi cross build"
    TOOLCHAIN_OPT="--enable-cross-compile --target-os=linux --arch=arm"
    SYSROOT_CC=`${CROSS_PREFIX}gcc -print-sysroot` # TODO: not for clang
    [ -d "$SYSROOT_CC/opt/vc" ] || SYSROOT_CC=
  }
  : ${SYSROOT:=${SYSROOT_CC}}
  [ -d "$SYSROOT/opt/vc" ] || {
    echo "rpi sysroot is not found!"
    exit 1
  }
  $rpi_cross && TOOLCHAIN_OPT+=" --sysroot=\\\$SYSROOT" # clang searchs host by default, so sysroot is required
  # probe compiler first
  setup_cc ${USE_TOOLCHAIN:=gcc} "--target=arm-linux-gnueabihf" # clang on mac(apple or opensource) will use apple flags w/o --target= 
  local SUBARCH=${ARCH}-a
# t.S: x .dn 0
# gas-preprocessor.pl -arch arm -as-type clang -- clang --target=armv7-none-linux-androideabi -march=armv7-a -mfloat-abi=softfp t.S -v -c
# clang -fintegrated-as --target=armv7-none-linux-androideabi -march=armv7-a -mfloat-abi=softfp -gcc-toolchain $ANDROID_NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/ t.S -v -c
# host build can always use binutils, so only cross build uses gas-pp
  $rpi_cross && $IS_CLANG && {
  # gas-preprocessor is used by configure internally. armv6t2 is required
    SUBARCH=${SUBARCH/6-a/6t2}
    $IS_APPLE_CLANG || TOOLCHAIN_OPT+=" --as='gas-preprocessor.pl -as-type clang -arch arm -- $USE_TOOLCHAIN'" # clang searchs host by default, so sysroot is required
  } || SUBARCH=${SUBARCH/6-a/6zk} # armv6kz is not supported by some compilers, but zk is.
  local EXTRA_CFLAGS_armv6="-march=$SUBARCH -mtune=arm1176jzf-s -mfpu=vfp -marm" # no thumb support, set -marm for clang or -mthumb-interwork for gcc
  local EXTRA_CFLAGS_armv7="-march=$SUBARCH -mtune=cortex-a7 -mfpu=neon-vfpv4 -mthumb" # -mthumb-interwork vfpv3-d16"
  local EXTRA_CFLAGS_armv8="-march=$SUBARCH -mtune=cortex-a53 -mfpu=neon-fp-armv8" # crypto extensions is optional for armv8a, and do not exist on rpi3

  if $IS_CLANG; then
    rpi_cc=clang
    use_llvm_binutils
    $IS_APPLE_CLANG && : ${USE_LD:="/usr/local/opt/llvm/bin/clang"}
  fi
  # --cross-prefix is used by binutils (strip, but linux host ar, ranlib, nm can be used for cross build)
  $HAVE_LLD && {
    [[ "${USE_LD##*/}" == "lld" ]] && {
      use_lld -flavor gnu
    } || {
      use_lld
    }
  } || {
    $rpi_cross && TOOLCHAIN_OPT="--cross-prefix=$CROSS_PREFIX $TOOLCHAIN_OPT"
  }
  USER_OPT="--enable-omx-rpi --enable-mmal $USER_OPT"
  include_with_sysroot "/opt/vc/include" "/opt/vc/include/IL"
  # https://github.com/carlonluca/pot/blob/master/piomxtextures_tools/compile_ffmpeg.sh
  # -funsafe-math-optimizations -mno-apcs-stack-check -mstructure-size-boundary=32 -mno-sched-prolog
  # not only rpi vc libs, but also gcc headers and libs in sysroot may be required by some toolchains, so simply set --sysroot= may not work
  # armv6zk, armv6kz, armv6z: https://reviews.llvm.org/D14568
  eval EXTRA_CFLAGS_RPI='${EXTRA_CFLAGS_'$ARCH'}'
  EXTRA_CFLAGS+=" $CFLAGS_CLANG $CLANG_FLAGS $EXTRA_CFLAGS_RPI -mfloat-abi=hard"
  $LD_IS_LLD || EXTRA_LDFLAGS+=" $LFLAGS_CLANG $CLANG_FLAGS"
  EXTRA_LDFLAGS+=" -L\\\$SYSROOT/opt/vc/lib"
  #-lrt: clock_gettime in glibc2.17
  EXTRALIBS+=" -lrt"
  test -f /bin/sh.exe || EXTRA_LDFLAGS+=" -Wl,-rpath-link,\\\$SYSROOT/opt/vc/lib"
  INSTALL_DIR=sdk-$2-${ARCH}-${rpi_cc}
}

# TODO: generic linux for all archs
setup_linux_env() {
  : ${USE_TOOLCHAIN:=gcc}
  probe_cc $USE_TOOLCHAIN
  add_elf_flags
  enable_libmfx
  enable_opt vaapi vdpau
  local CC_ARCH=`$USE_TOOLCHAIN -dumpmachine`
  CC_ARCH=${CC_ARCH%%-*}
  local CC_BIT=64
  [ -n "${CC_ARCH/*64/}" ] && CC_BIT=32
  local ARCH=$1
  local BIT=64
  [ -z "$ARCH" -o "$ARCH" == "linux" ] && ARCH=$CC_ARCH
  [ -n "${ARCH/*64/}" ] && BIT=32
  [ $BIT -ne $CC_BIT ] && {
    EXTRA_CFLAGS="-m$BIT $EXTRA_CFLAGS"
    EXTRA_LDFLAGS="-m$BIT $EXTRA_LDFLAGS"
  }
  $IS_CLANG && {
    EXTRA_CFLAGS+=" $CFLAGS_CLANG $CLANG_FLAGS"
    EXTRA_LDFLAGS+=" $LFLAGS_CLANG $CLANG_FLAGS"
    $HAVE_LLD && [ $BIT -eq 64 ] && use_lld # 32bit error: can't create dynamic relocation R_386_32 against local symbol in readonly segment   libavutil/x86/float_dsp.o
  } || {
    EXTRA_CFLAGS+=" $CFLAGS_GCC $GCC_FLAGS"
    EXTRA_LDFLAGS+=" $LFLAGS_GCC $GCC_FLAGS"
  }
  [ "$USE_TOOLCHAIN" == "gcc" ] || TOOLCHAIN_OPT="--cc=$USE_TOOLCHAIN $TOOLCHAIN_OPT"
  INSTALL_DIR=${USE_TOOLCHAIN##*/}
  INSTALL_DIR=${INSTALL_DIR%%-*}
  INSTALL_DIR=sdk-linux-${ARCH}-${INSTALL_DIR}
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
  : ${VC_BUILD:=false} #global is fine because no parallel configure now
  add_librt(){
  # clock_gettime in librt instead of glibc>=2.17
    grep -q "LIBRT" $FFSRC/configure && {
      # TODO: cc test
      host_is Linux && ! target_is android && ! echo $EXTRALIBS |grep -q '\-lrt' && ! echo $EXTRA_LDFLAGS |grep -q '\-lrt' && EXTRALIBS+=" -lrt"
    }
  }
  case $1 in
    android*)    setup_android_env $TAGET_ARCH_FLAG $1 ;;
    ios*)       setup_ios_env $TAGET_ARCH_FLAG $1 ;;
    osx*|macos*)     setup_macos_env $TAGET_ARCH_FLAG $1 ;;
    mingw*)     setup_mingw_env $TAGET_ARCH_FLAG ;;
    vc)         setup_vc_env $TAGET_ARCH_FLAG $1 ;;
    win*)       setup_win $TAGET_ARCH_FLAG $1 ;; # TODO: check cc
    rpi*|raspberry*) setup_rpi_env $TAGET_ARCH_FLAG $1 ;;
    linux*)
      setup_linux_env $TAGET_ARCH_FLAG $1
      add_librt
      ;;
    clang*)
      setup_win_clang $TAGET_ARCH_FLAG $1
      ;;
    *) # assume host build. use "") ?
      if $VC_BUILD; then
        setup_vc_env $TAGET_ARCH_FLAG
      elif host_is MinGW || host_is MSYS; then
        setup_mingw_env
      elif host_is Linux; then
        if [ -c /dev/vchiq ]; then
          setup_rpi_env armv6zk rpi
        else
          setup_linux_env $TAGET_ARCH_FLAG
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
      TOOLCHAIN_OPT+=" --enable-lto"
    fi
  fi
  $enable_pic && TOOLCHAIN_OPT+=" --enable-pic"
  EXTRA_CFLAGS=$(trim2 $EXTRA_CFLAGS)
  EXTRA_LDFLAGS=$(trim2 $EXTRA_LDFLAGS)
  EXTRA_LDSOFLAGS=$(trim2 $EXTRA_LDSOFLAGS)
  EXTRALIBS=$(trim2 $EXTRALIBS)
  test -n "$EXTRA_CFLAGS" && TOOLCHAIN_OPT+=" --extra-cflags=\"$EXTRA_CFLAGS\""
  test -n "$EXTRA_LDFLAGS" && TOOLCHAIN_OPT+=" --extra-ldflags=\"$EXTRA_LDFLAGS\""
  test -n "$EXTRA_LDSOFLAGS" && TOOLCHAIN_OPT+=" --extra-ldsoflags=\"$EXTRA_LDSOFLAGS\""
  test -n "$EXTRALIBS" && TOOLCHAIN_OPT+=" --extra-libs=\"$EXTRALIBS\""
  echo INSTALL_DIR: $INSTALL_DIR
  is_libav || FEATURE_OPT+=" --enable-avresample --disable-postproc"
  local CONFIGURE="configure --extra-version=QtAV --disable-doc ${DEBUG_OPT} $LIB_OPT --enable-runtime-cpudetect $FEATURE_OPT $TOOLCHAIN_OPT $USER_OPT"
  : ${NO_ENC=false}
  if ! $NO_ENC && [ -n "$ENC_OPT" ]; then
    CONFIGURE+=" $ENC_OPT $MUX_OPT"
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
  fi
  if [ $? -eq 0 ]; then
    echo $CONFIGURE >config.txt
    echo $FFVERSION_FULL >>config.txt
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
    LLD_AS_LD=false
    grep -q "lld -flavor" $CONFIG_MAK && LLD_AS_LD=true # check lld-link?
    $LLD_AS_LD && { # remove -Wl flags add by configure. they are not supported by lld, but lld only reports warnings
      echo "patching lld flags..."
      sed -i $sed_bak '/SHFLAGS=/s/-Wl,//g;/SHFLAGS=/s/,/ /g;/SHFLAGS=/s/-dynamiclib//g;/SHFLAGS=/s/-Bsymbolic//g' $CONFIG_MAK
      sed -i $sed_bak -e '/LDFLAGS=/s/-Wl,//g;/LDFLAGS=/s/,/ /g' $CONFIG_MAK
      sed -i $sed_bak -e '/LDFLAGS=/s/--as-needed//g;/LDFLAGS=/s/-z noexecstack//g;/LDFLAGS=/s/--warn-common//g;/LDFLAGS=/s/-rpath-link=.*//g' $CONFIG_MAK
    }
    local MAX_SLICES=`grep '#define MAX_SLICES' $FFSRC/libavcodec/h264dec.h 2>/dev/null`
    if [ -n "$MAX_SLICES" ]; then
      MAX_SLICES=`echo $MAX_SLICES |cut -d ' ' -f 3`
      if [ "$MAX_SLICES" -lt 64 ]; then
        echo "patching MAX_SLICES..."
        sed -i $sed_bak 's/\(#define MAX_SLICES\) .*/\1 64/' $FFSRC/libavcodec/h264dec.h
      fi
    fi
    if ! `grep -q SETDLLDIRECTORY_PATCHED $FFSRC_TOOLS/cmdutils.c`; then # cl, clang and clang-cl
      sed -i $sed_bak "/SetDllDirectory(\"\")/i\\
\#if (_WIN32_WINNT+0) >= 0x0502  \/\/SETDLLDIRECTORY_PATCHED\\
" "$FFSRC_TOOLS/cmdutils.c"
      sed -i $sed_bak "/SetDllDirectory(\"\")/a\\
\#endif\\
" "$FFSRC_TOOLS/cmdutils.c"
    fi
    if $VC_BUILD; then # check ffmpeg version?
      if [ "${VisualStudioVersion:0:2}" -gt 14 ] && `echo $LANG |grep -q zh` && [ ! -f config-utf8.h ] ; then  # check ffmpeg version?
        iconv -t "UTF-8" -f "GBK" config.h > config-utf8.h
        cp -f config{-utf8,}.h
      fi
      # ffmpeg.c includes compat/atomics/win32/stdatomic.h which includes winsock.h (from windows.h), os_support.h includes winsock2.h later and then have duplicated definations. winsock2,h defines _WINSOCKAPI_ to prevent inclusion of winsock.h in windows.h
      if ! `grep -q WINSOCK_PATCHED $FFSRC_TOOLS/ffmpeg.c`; then
        sed -i '/#include "config.h"/a #include "libavformat/os_support.h"  \/\/WINSOCK_PATCHED' $FFSRC_TOOLS/ffmpeg.c
      fi
    fi
    if [ -n "$PATCH_MMAP" ] && `grep -q 'HAVE_MMAP 1' config.h` ; then
      #sed -i $sed_bak "/#define FFMPEG_CONFIG_H/a\\
      #$PATCH_MMAP \/\*MMAP_PATCHED\*\/\\
      #" config.h
      sed -i $sed_bak 's/\(#define HAVE_MMAP\) .*/\1 0/' config.h
    fi
  else
    tail -n 20 ffbuild/config.log 2>/dev/null || tail -n 20 avbuild/config.log 2>/dev/null || tail -n 20 config.log 2>/dev/null #libav moves config.log to avbuild dir
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
  cp -af $FFSRC/{Changelog,RELEASE_NOTES} .
  [ -f "$FFSRC/$LICENSE_FILE" ] && cp -af "$FFSRC/$LICENSE_FILE" . || touch $LICENSE_FILE
  if [ -f bin/avutil.lib ]; then
    mv bin/*.lib lib
  fi
}

build_all(){
  local os=`tolower $1`
  local USE_TOOLCHAIN=$USE_TOOLCHAIN
  [ ! "${USE_TOOLCHAIN/clang/}" = "${USE_TOOLCHAIN}" ] && IS_CLANG=true
  [ -z "$os" ] && {
    config1 $@
  } || {
    local archs=($2)
    [ -z "$archs" ] && {
      echo ">>>>>no arch is set. setting default archs..."
      [ "${os:0:3}" == "ios" ] && archs=(armv7 arm64 x86 x86_64)
      [ "${os:0:7}" == "android" ] && archs=(armv5 armv7 arm64 x86)
      [ "${os:0:3}" == "rpi" -o "${os:0:9}" == "raspberry" ] && archs=(armv6zk armv7-a)
      [ "${os:0:5}" == "mingw" ] && archs=(x86 x86_64)
      [ "${os:0:2}" == "vc" -o "${os:0:3}" == "win" ] && archs=(x86 x64)
      [[ "${os:0:5}" == "winrt" || "${os:0:3}" == "uwp" || "${os:0:8}" == "winstore" ]] && archs=(x86 x64 arm)
      #[ "${os:0:5}" == "macos" ] && archs=(x86_64 i386)
    }
    echo ">>>>>archs: ${archs[@]}"
    [ -z "$archs" ] && {
      config1 $os
    } || {
      local CONFIG_JOBS=()
      USE_TOOLCHAIN0=$USE_TOOLCHAIN
      for arch in ${archs[@]}; do
        if [ -z "${arch/*clang*/}" ]; then
          IS_CLANG=true
          USE_TOOLCHAIN="clang${arch##*clang}"
          arch=${arch%%?clang*}
        elif [ -z "${arch/*gcc*/}" ]; then
          IS_CLANG=false
          USE_TOOLCHAIN="gcc${arch##*gcc}"
          arch=${arch%%?gcc*}
        fi
        CONFIG_JOBS=(${CONFIG_JOBS[@]} %$((${#CONFIG_JOBS[@]}+1)))
        # TODO: will vars (IS_CLANG, arch, USE_TOOLCHAIN) in sub process be modified by other process?
        config1 $os $arch &
        USE_TOOLCHAIN=$USE_TOOLCHAIN0
      done
      [ ${#CONFIG_JOBS[@]} -gt 0 ] && {
        echo "waiting for all configure jobs(${#CONFIG_JOBS[@]}) finished..."
        wait ${CONFIG_JOBS[@]}
        [ $? == 0 ] && echo "all configuration are finished" || exit 1
      }
    }
  }
  cd $THIS_DIR
  dirs=`ls .dir`
  rm -rf .dir
  for d in $dirs; do
    cd build_$d
    local INSTALL_DIR=$d
    CONFIGURE=`cat config-new.txt`
    # "$CONFIGURE" is not empty, so check -z is enough
    [ -z "${CONFIGURE/*--enable-gpl*/}" ] && LICENSE=GPL || LICENSE=LGPL
    [ -z "${CONFIGURE/*--enable-version3*/}" ] && LICENSE=${LICENSE}v3 || LICENSE=${LICENSE}v2.1
    [ -z "${CONFIGURE/*--enable-nonfree*/}" ] && LICENSE=nonfree
    LICENSE_FILE=COPYING.$LICENSE
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
  [ ${#dirs[@]} -le 1 ] && return 0
  if [ "${os:0:3}" == ios ]; then
    local OUT_DIR=sdk-$os
    rm -rf $OUT_DIR
    cd $THIS_DIR
    mkdir -p $OUT_DIR/lib
    cp -af ${dirs[0]}/include $OUT_DIR
    for a in libavutil libavformat libavcodec libavfilter libavresample libavdevice libswscale libswresample; do
      libs=
      for d in ${dirs[@]}; do
        [ -f $d/lib/${a}.a ] && libs+=" $d/lib/${a}.a"
      done
      echo "lipo -create $libs -o $OUT_DIR/lib/${a}.a"
      test -n "$libs" && {
        lipo -create $libs -o $OUT_DIR/lib/${a}.a
        lipo -info $OUT_DIR/lib/${a}.a
      }
    done
    cat build_sdk-${os}-*/config.txt >$OUT_DIR/config.txt
    cp -af $FFSRC/{Changelog,RELEASE_NOTES} $OUT_DIR
    [ -f "$FFSRC/$LICENSE_FILE" ] && cp -af "$FFSRC/$LICENSE_FILE" $OUT_DIR || touch $OUT_DIR/$LICENSE_FILE
    echo "https://github.com/wang-bin/avbuild" >$OUT_DIR/README.txt
    rm -rf ${dirs[@]}
  else
    local get_arch=echo
    [ "$os" == "android" ] && get_arch=android_arch
    rm -rf sdk-$os-{gcc,clang,cl${VS_CL}}
    for d in ${dirs[@]}; do
      USE_TOOLCHAIN=${d##*-}
      [ "${USE_TOOLCHAIN/gcc/}" == "${USE_TOOLCHAIN}" -a "${USE_TOOLCHAIN/clang/}" == "$USE_TOOLCHAIN" -a "${USE_TOOLCHAIN/cl/}" == "$USE_TOOLCHAIN" ] && USE_TOOLCHAIN=gcc
      OUT_DIR=sdk-$os-${USE_TOOLCHAIN}
      arch=${d%-*}
      arch=${arch#sdk-$os-}
      arch=${arch#sdk-$os}
      arch="$($get_arch $arch)"
      [ "${arch:0:3}" == "sdk" ] && arch=  # single arch build
      mkdir -p $OUT_DIR/{bin,lib}/$arch
      cp -af $d/include $OUT_DIR
      cp -af $d/bin/* $OUT_DIR/bin/$arch
      cp -af $d/lib/* $OUT_DIR/lib/$arch
      cat $d/config.txt >$OUT_DIR/config-$arch.txt
      cp -af $FFSRC/{Changelog,RELEASE_NOTES} $OUT_DIR
      [ -f "$FFSRC/$LICENSE_FILE" ] && cp -af "$FFSRC/$LICENSE_FILE" $OUT_DIR || touch $OUT_DIR/$LICENSE_FILE
      echo "https://github.com/wang-bin/avbuild" >$OUT_DIR/README.txt
      rm -rf $d
    done
  fi
}
mkdir -p .dir

build_all "$@"
echo ${SECONDS}s elapsed
