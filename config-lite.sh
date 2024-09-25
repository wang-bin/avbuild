USER_OPT="--enable-small \
--disable-outdevs \
--disable-filters \
--disable-muxers \
--disable-encoders \
--disable-decoders \
--disable-demuxers \
--disable-protocols \
$USER_OPT
"
DEC_OPT_MOBILE="--enable-decoder=*sub*,movtext,*web*,aac*,ac3*,eac3*,alac*,ape,ass,ccaption,cfhd,cook,dca,dnxhd,exr,truehd,*yuv*,flv,flac,gif,h26[3-4]*,hevc*,hap,mp[1-3]*,prores,*[mj]peg*,mlp,mpl2,nellymoser,opus,pcm*,qtrle,*png*,tiff,rawvideo,rv*,sami,srt,ssa,v210*,vc1*,vorbis,vp[6-9]*,wm*,wrapped_avframe"
DEMUX_OPT_MOBILE="--enable-demuxer=*sub*,*ac3,*ac,*avs*,*[mj]peg*,*vc*,*web*,au,ape,ass,av[1i],concat,dnxhd,dts*,*dash*,*flv,gif,hls,h264,kux,matroska,mov,mp3,mxf,obu,ogg,pcm*,rawvideo,rt*p,spdif,srt,v210*,wav,*pipe,image2"
ENC_OPT_MOBILE="--enable-encoder=*_at,aac,gif,h26[3-4]*,av1*,hevc*,mjpeg*,*png,opus,pcm*,prores*,rawvideo,spdif,speedhq,*jpeg,*png,vp[8-9]*,wrapped_avframe"
MUX_OPT_MOBILE="--enable-muxer=*jpeg,fifo,flv,gif,hls,h264,hevc,image2,mov,mp4,mpegts,matroska,null,pcm*,rawvideo,spdif,*pipe,*segment,webm,wav"
PROT_OPT_MOBILE="--enable-protocol=cache,concat*,crypto*,data,fd,*file,ftp,h*,i*,pipe,rt*,s*,t*,u*"
FILTER_OPT_MOBILE="--enable-filter=*null*,afade,*fifo,*format,*resample,aeval,atempo,pan,crop,eq*,framerate,hw*,scale,volume"
PROT_OPT="${PROT_OPT_MOBILE}"
# av1: only hwaccel no native, only desktop hwaccels support av1
DEC_OPT="${DEC_OPT_MOBILE},av1*,ffv*"          # vvc*
DEMUX_OPT="${DEMUX_OPT_MOBILE},mlv,nsv,nut"     # vvc
ENC_OPT="${ENC_OPT_MOBILE},ff*,*nvenc,*qsv,*v4l2m2m,*vaapi,vorbis,*yuv*"
MUX_OPT="${MUX_OPT_MOBILE},dash,nu*,og*"
FILTER_OPT="$FILTER_OPT_MOBILE,allrgb,allyuv,*bars,color,test*,*key,draw*,*_qsv,*_vaapi,*v4l2*"
android_OPT="--disable-avdevice"
ios_OPT="--disable-avdevice"
rpi_OPT="--disable-avdevice"
raspberry_pi_OPT="--disable-avdevice"
sunxi_OPT="--disable-avdevice"
LITE_BUILD=true