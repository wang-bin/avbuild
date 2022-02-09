USER_OPT="--enable-small \
--disable-outdevs \
--disable-filters \
--enable-filter=*null*,afade,*fifo,*format,*resample,aeval,allrgb,allyuv,atempo,pan,*bars,color,*key,crop,draw*,eq*,framerate,*_qsv,*_vaapi,*v4l2*,hw*,scale,volume,test* \
--disable-muxers \
--disable-encoders \
--disable-decoders \
--disable-demuxers \
--disable-parsers --enable-parser=*sub*,*jp*,aac*,ac3,cook,dnxhd,flac,h26[3-4],hevc,m*,opus,rv*,vc1,vorbis,vp[8-9] \
--pkg-config=pkg-config --pkg-config-flags=--static --enable-gpl --enable-libx265 --enable-libx264 \
$USER_OPT
"
DEC_OPT_MOBILE="--enable-decoder=*sub*,movtext,*web*,aac*,*ac3*,alac*,ape,ass,av1*,ccaption,cfhd,cook,dca,dnxhd,eac3*,exr,truehd,ff*,*yuv*,flv,flac,gif,h26[3-4]*,hevc*,hap,mp[1-3]*,prores,*peg*,mlp,mpl2,nellymoser,opus,pcm*,qtrle,*png*,tiff,rawvideo,sami,srt,ssa,v210*,vc1*,vorbis,vp[6-9]*,wm*,wrapped_avframe"
DEMUX_OPT_MOBILE="--enable-demuxer=*sub*,*ac3,*ac,*peg*,*web*,au,ape,ass,avi,concat,dnxhd,dts*,*dash*,*flv,gif,hls,h264,hevc,kux,matroska,mov,mp3,mxf,ogg,pcm*,rawvideo,rt*p,spdif,srt,vc1,v210*,wav,*pipe,image2"
ENC_OPT_MOBILE="--enable-encoder=libx26*,aac,cfhd,dnxhd,exr,ff*,*yuv*,gif,h26[3-4]*,av1*,hevc*,mjpeg*,*png,opus,pcm*,prores*,rawvideo,spdif,speedhq,*jpeg,*png,tiff,vp[8-9]*,wrapped_avframe"
MUX_OPT_MOBILE="--enable-muxer=*jpeg,dnxhd,fifo,flv,gif,hls,h264,hevc,image2,mov,mp4,mpegts,matroska,null,og*,pcm*,rawvideo,spdif,*pipe,*segment,webm,wav"
DEC_OPT="${DEC_OPT_MOBILE},rv*"
DEMUX_OPT="${DEMUX_OPT_MOBILE},mlv,nsv,nut"
ENC_OPT="${ENC_OPT_MOBILE},*nvenc,*qsv,*v4l2m2m,*vaapi,vorbis"
MUX_OPT="${MUX_OPT_MOBILE},dash,nu*"
android_OPT="--disable-avdevice"
ios_OPT="--disable-avdevice"
rpi_OPT="--disable-avdevice"
raspberry_pi_OPT="--disable-avdevice"
sunxi_OPT="--disable-avdevice"
