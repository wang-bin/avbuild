. config-lite.sh
INSTALL_DIR=sdk-rpi
: {CROSS_PREFIX:=arm-linux-gnueabihf-}
uname -a |grep armv && {
  echo "rpi host build"
  SYSROOT=`gcc -print-sysroot`
  TOOLCHAIN_OPT="--cpu=armv6"
} || {
  echo "rpi cross build"
  TOOLCHAIN_OPT="--enable-cross-compile --cross-prefix=$CROSS_PREFIX --target-os=linux --arch=arm --cpu=armv6"
  SYSROOT_CROSS=`${CROSS_PREFIX}gcc -print-sysroot`
}
: {SYSROOT:=${SYSROOT_CROSS}}
USER_OPT="$USER_OPT --enable-omx-rpi --enable-mmal"
# FIXME: isystem path with spaces can not use ""
# -mfloat-abi=hard to linker for multilib gcc (arm gcc)
# https://github.com/carlonluca/pi/piomxtextures_tools/compile_ffmpeg.sh
COMMON_FLAGS="-funsafe-math-optimizations -mno-apcs-stack-check -mstructure-size-boundary=32 -mno-sched-prolog"
EXTRA_CFLAGS_PI2="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard $COMMON_FLAGS"
EXTRA_CFLAGS_PI3="-march=armv8-a -mtune=cortex-a53 -mfpu=crypto-neon-fp-armv8 -mfloat-abi=hard $COMMON_FLAGS"
EXTRA_CFLAGS="-mfloat-abi=hard -mfpu=vfp $COMMON_FLAGS -isystem$SYSROOT/opt/vc/include -isystem$SYSROOT/opt/vc/include/IL"
EXTRA_LDFLAGS="-mfloat-abi=hard -L$SYSROOT/opt/vc/lib"
#-lrt: clock_gettime in glibc2.17
[ "`${CROSS_PREFIX}gcc -print-file-name=librt.so`" = "librt.so" ] || EXTRA_LDFLAGS="$EXTRA_LDFLAGS -lrt"
${CROSS_PREFIX}gcc --version |grep "ARM Embedded Processors" &>/dev/null && {
  #__nothrow__ __LEAF
  EXTRA_CFLAGS="$EXTRA_CFLAGS -I$SYSROOT/usr/include -I$SYSROOT/opt/vc/include/interface/vcos/pthreads -I$SYSROOT/opt/vc/include/interface/vmcs_host/linux"
  EXTRA_LDFLAGS="$EXTRA_LDFLAGS --specs=nosys.specs -Wl,-rpath-link,$SYSROOT/lib"
  enable_lto=false
}
test -f /bin/sh.exe || EXTRA_LDFLAGS="-Wl,-rpath-link,$SYSROOT/opt/vc/lib $EXTRA_LDFLAGS"
