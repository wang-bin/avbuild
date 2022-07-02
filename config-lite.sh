USER_OPT="--h264-max-bit-depth=10 \
--enable-small \
--disable-outdevs \
--disable-filters \
--enable-filter=*null*,afade,*fifo,*format,*resample,aeval,allrgb,allyuv,atempo,pan,*bars,color,*key,crop,draw*,eq*,framerate,*_qsv,*_vaapi,*v4l2*,hw*,scale,volume,test* \
--disable-muxers \
--disable-encoders \
--disable-decoders \
--enable-decoder=*sub*,movtext,*web*,aac*,*ac3*,alac*,ape,ass,av1*,cc_dec,cook,dca,dnxhd,eac3*,exr,truehd,ff*,*yuv*,flv,flac,gif,h26[3-4]*,hevc*,hap,mp[1-3]*,prores,*peg*,mlp,mpl2,nellymoser,opus,pcm*,*png*,tiff,rawvideo,rv*,sami,srt,ssa,v210*,vc1*,vorbis,vp[6-9]*,wm*,wrapped_avframe \
--disable-demuxers \
--enable-demuxer=*sub*,*ac3,*ac,*peg*,*web*,ape,ass,avi,concat,dnxhd,dts*,*dash*,*flv,gif,hls,h264,hevc,kux,xv,matroska,mlv,mov,mp3,mxf,nsv,nut,ogg,pcm*,rawvideo,rt*p,spdif,srt,vc1,v210*,wav,*pipe,image2 \
--disable-parsers --enable-parser=*sub*,aac*,ac3,cook,dnxhd,flac,h26[3-4],hevc,m*,opus,rv*,vc1,vorbis,vp[8-9] \
$USER_OPT
"
ENC_OPT_MOBILE="--enable-encoder=aac,dnxhd,exr,ff*,*yuv*,gif,h26[3-4]*,hevc*,mjpeg,*png,opus,pcm*,prores*,rawvideo,spdif,speedhq,*jpeg,*png,vp[7-9],wrapped_avframe"
MUX_OPT_MOBILE="--enable-muxer=*jpeg,dnxhd,fifo,flv,gif,hls,h264,hevc,image2,mov,mp4,mpegts,matroska,null,og*,pcm*,rawvideo,spdif,*pipe,*segment,webm,wav"
ENC_OPT="${ENC_OPT_MOBILE},nvenc*,vorbis"
MUX_OPT="${MUX_OPT_MOBILE},dash,nu*"
android_OPT="--disable-avdevice"
ios_OPT="--disable-avdevice"
rpi_OPT="--disable-avdevice"
raspberry_pi_OPT="--disable-avdevice"
sunxi_OPT="--disable-avdevice"
