USER_OPT="--enable-small --disable-avdevice --disable-avresample \
--disable-filters \
--enable-filter=aeval,afade,aformat,all*,amix,arealtime,aresample,asplit,atempo,color*,blend,con*,draw*,eq*,fade,format,frame*,null,overlay,pad,split,volume \
--disable-muxers \
--enable-muxer=dash,fifo,gif,h264,hevc,hls,mjpeg,matroska*,mov,mp4,mpegts,nu*,og*,opus,pcm*,rawvideo,rtp,rtsp,wav \
--disable-encoders \
--enable-encoder=aac,gif,h26[3-4]*,hevc*,mjpeg,mpeg[2-4]*,nellymoser,nvenc*,opus,pcm*,rawvideo,vorbis \
--disable-decoders \
--enable-decoder=aac*,ac3*,ape,ass,cook,eac3,flv,flac,h264*,hevc*,mjpeg*,mp[1-3]*,*mpeg*,nellymoser,opus,pcm*,rv*,srt,ssa,v210*,vc1*,vorbis,vp[6-9],wmv* \
--disable-demuxers \
--enable-demuxer=aac,ac3,ape,ass,avi,concat,eac3,flac,*flv,hls,h264,hevc,matroska,mjpeg*,mov,mpeg*,mp3,mxf,nsv,nut,ogg,rawvideo,rt*p,srt,vc1,v210*,wav \
--disable-bsfs --enable-bsf=aac*,mjpeg*,*mov*,*mp*,vp9* \
--disable-parsers --enable-parser=aac*,ac3,cook,flac,h26[3-4],hevc,mjpeg*,mpeg*,opus,rv*,vc1,vorbis,vp[8-9] \
$USER_OPT
"
# nellymoser: used by flash video, longzhu
# LIB_OPT="--enable-shared"
#TODO: image2?
