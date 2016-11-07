. config-lite.sh
SYSROOT=`arm-linux-gnueabihf-gcc -print-sysroot`
USER_OPT="$USER_OPT --enable-omx-rpi --enable-mmal \
--enable-muxer=mov,mp4,matroska,hls,mpegts,tee,rtsp \
--enable-encoder=h264_omx,aac*"
TOOLCHAIN_OPT="--enable-cross-compile --cross-prefix=arm-linux-gnueabihf- --target-os=linux --arch=arm --cpu=armv6"
EXTRA_CFLAGS="-mfloat-abi=hard -mfpu=vfp -isystem$SYSROOT/opt/vc/include -isystem$SYSROOT/opt/vc/include/IL"
EXTRA_LDFLAGS="-L$SYSROOT/opt/vc/lib -lrt" #-lrt: clock_gettime in glibc2.17 
