. config-lite.sh
uname -a |grep armv && {
  echo "rpi host build"
  SYSROOT=`gcc -print-sysroot`
  TOOLCHAIN_OPT="--cpu=armv6"
} || {
  echo "rpi cross build"
  TOOLCHAIN_OPT="--enable-cross-compile --cross-prefix=arm-linux-gnueabihf- --target-os=linux --arch=arm --cpu=armv6"
  SYSROOT=`arm-linux-gnueabihf-gcc -print-sysroot`
}
SYSROOT=`arm-linux-gnueabihf-gcc -print-sysroot`
USER_OPT="$USER_OPT --enable-omx-rpi --enable-mmal \
--enable-muxer=mov,mp4,matroska,hls,mpegts,tee,rtsp \
--enable-encoder=h264_omx,aac*"
EXTRA_CFLAGS="-mfloat-abi=hard -mfpu=vfp -isystem$SYSROOT/opt/vc/include -isystem$SYSROOT/opt/vc/include/IL"
EXTRA_LDFLAGS="-L$SYSROOT/opt/vc/lib -lrt" #-lrt: clock_gettime in glibc2.17 
test -f /bin/sh.exe || EXTRA_LDFLAGS="-Wl,-rpath-link,$SYSROOT/opt/vc/lib $EXTRA_LDFLAGS"
