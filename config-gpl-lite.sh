USER_OPT="--enable-small \
--disable-outdevs \
--disable-filters \
--disable-muxers \
--disable-encoders \
--disable-decoders \
--disable-demuxers \
--disable-protocols \
--disable-parsers --enable-parser=*sub*,*jp*,aac*,ac3,cook,dnxhd,flac,h26[3-4],hevc,m*,opus,rv*,vc1,vorbis,vp[8-9] \
--pkg-config=pkg-config --pkg-config-flags=--static --enable-gpl --enable-libx265 --enable-libx264 \
--enable-libfreetype --enable-libharfbuzz \
$USER_OPT
"
DEC_OPT_MOBILE="--enable-decoder=*sub*,movtext,*web*,aac*,ac3*,eac3*,alac*,ape,ass,av1*,ccaption,cfhd,cook,dca,dnxhd,exr,truehd,*yuv*,flv,flac,gif,h26[3-4]*,hevc*,hap,mp[1-3]*,prores,*[mj]peg*,mlp,mpl2,nellymoser,opus,pcm*,qtrle,*png*,tiff,rawvideo,sami,srt,ssa,v210*,vc1*,vorbis,vp[6-9]*,wm*,wrapped_avframe"
DEMUX_OPT_MOBILE="--enable-demuxer=*sub*,*ac3,*ac,*avs*,*[mj]peg*,*vc*,*web*,au,ape,ass,av[1i],concat,dnxhd,dts*,*dash*,*flv,gif,hls,h264,kux,matroska,mov,mp3,mxf,obu,ogg,pcm*,rawvideo,rt*p,spdif,srt,v210*,wav,*pipe,image2"
ENC_OPT_MOBILE="--enable-encoder=libx26*,aac,cfhd,dnxhd,exr,ff*,flv,*yuv*,gif,h26[3-4]*,av1*,hevc*,mjpeg*,*png,opus,pcm*,prores*,rawvideo,spdif,speedhq,*jpeg,*png,tiff,vp[8-9]*,wrapped_avframe"
MUX_OPT_MOBILE="--enable-muxer=*jpeg,dnxhd,fifo,flv,gif,hls,h264,hevc,image2,mov,mp4,mpegts,matroska,null,og*,pcm*,rawvideo,rt*,spdif,*pipe,*segment,webm,wav"
PROT_OPT_MOBILE="--enable-protocol=cache,concat*,crypto*,data,fd,*file,ftp,h*,i*,pipe,rt*,s*,t*,u*"
FILTER_OPT_MOBILE="--enable-filter=drawtext,*null*,afade,*fifo,*format,*resample,aeval,atempo,pan,crop,eq*,framerate,hw*,loudnorm,scale,volume,yadif*,*movie,overlay"
PROT_OPT="${PROT_OPT_MOBILE}"
DEC_OPT="${DEC_OPT_MOBILE},rv*,ffv*"
DEMUX_OPT="${DEMUX_OPT_MOBILE},mlv,nsv,nut"
ENC_OPT="${ENC_OPT_MOBILE},*nvenc,*qsv,*v4l2m2m,*vaapi,vorbis"
MUX_OPT="${MUX_OPT_MOBILE},dash,nu*"
FILTER_OPT="$FILTER_OPT_MOBILE,allrgb,allyuv,*bars,color,test*,*key,draw*,*_qsv,*_vaapi,*v4l2*"
#android_OPT="--disable-avdevice"
ios_OPT="--disable-avdevice"
rpi_OPT="--disable-avdevice"
raspberry_pi_OPT="--disable-avdevice"
sunxi_OPT="--disable-avdevice"
rockchip_OPT="--enable-libfribidi --enable-fontconfig --enable-version3 --enable-rkmpp"
linux_OPT="--enable-libfribidi --enable-fontconfig"
LITE_BUILD=true
