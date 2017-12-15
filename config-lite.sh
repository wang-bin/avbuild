USER_OPT="--enable-small --disable-avdevice --disable-avresample \
--disable-filters \
--enable-filter=aeval,afade,aformat,all*,amix,arealtime,aresample,asplit,atempo,color*,blend,con*,draw*,eq*,fade,format,frame*,hw*,null,overlay,pad,split,volume \
--disable-muxers \
--disable-encoders \
--disable-decoders \
--enable-decoder=aac*,ac3*,alac*,ape,ass,cook,eac3,flv,flac,h264*,hevc*,mp[1-3]*,*m*peg*,nellymoser,opus,pcm*,rawvideo,rv*,srt,ssa,v210*,vc1*,vorbis,vp[6-9],wm*,wrapped_avframe \
--disable-demuxers \
--enable-demuxer=aac,ac3,ape,ass,avi,concat,dash,eac3,flac,*flv,hls,h264,hevc,matroska,mjpeg*,mlv,mov,mpeg*,mp3,mxf,nsv,nut,ogg,pcm*,rawvideo,rt*p,srt,vc1,v210*,wav,yuv4mpegpipe \
--disable-bsfs --enable-bsf=aac*,mjpeg*,*mov*,*mp*,vp9* \
--disable-parsers --enable-parser=aac*,ac3,cook,flac,h26[3-4],hevc,mjpeg*,mpeg*,opus,rv*,vc1,vorbis,vp[8-9] \
$USER_OPT
"
ENC_OPT="--enable-encoder=aac,gif,h26[3-4]*,hevc*,mjpeg,mpeg[2-4]*,nellymoser,nvenc*,opus,pcm*,rawvideo,vorbis,vp*,wrapped_avframe"
MUX_OPT="--enable-muxer=dash,fifo,gif,h264,hevc,hls,mjpeg,matroska*,mov,mp4,mpegts,nu*,og*,pcm*,rawvideo,rtp,rtsp,wav,webm,yuv4mpegpipe"
ENC_OPT_MOBILE="--enable-encoder=aac,gif,h264*,nellymoser,opus,pcm*"
MUX_OPT_MOBILE="--enable-muxer=gif,hls,mov,mp4,mpegts,wav"
# nellymoser: used by flash video, longzhu
# LIB_OPT="--enable-shared"
#TODO: image2?
