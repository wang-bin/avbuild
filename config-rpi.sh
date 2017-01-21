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
USER_OPT="$USER_OPT --enable-omx-rpi --enable-mmal \
--enable-muxer=mov,mp4,matroska,hls,mpegts,tee,rtsp \
--enable-encoder=h264_omx,aac*"
# FIXME: isystem path with spaces can not use ""
EXTRA_CFLAGS="-mfloat-abi=hard -mfpu=vfp -isystem$SYSROOT/opt/vc/include -isystem$SYSROOT/opt/vc/include/IL"
EXTRA_LDFLAGS="-L$SYSROOT/opt/vc/lib"
#-lrt: clock_gettime in glibc2.17
[ "`${CROSS_PREFIX}gcc -print-file-name=librt.so`" = "librt.so" ] || EXTRA_LDFLAGS="$EXTRA_LDFLAGS -lrt"
test -f /bin/sh.exe || EXTRA_LDFLAGS="-Wl,-rpath-link,$SYSROOT/opt/vc/lib $EXTRA_LDFLAGS"
