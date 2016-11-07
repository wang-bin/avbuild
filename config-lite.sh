USER_OPT="--enable-small --disable-avdevice --disable-avresample --disable-filters \
--enable-filter=aeval,afade,aformat,all*,amix,arealtime,aresample,asplit,atempo,color*,blend,con*,draw*,eq*,fade,format,frame*,null,overlay,pad,split,volume \
--disable-muxers --disable-encoders --disable-decoders \
--enable-decoder=aac*,ac3*,ass,ssa,eac3,srt,flv,flac,h264*,hevc*,vc1*,mp3,mpeg*,vp6*,vp7*,vp8*,vp9*,wma*,wmv*,opus,pcm*,wmv*,rv* \
--disable-demuxers --enable-demuxer=aac,concat,data,flv,hls,h264,hevc,live_flv,mov,mpegts,mpegps,ac3,ass,avi,eac3,flac,flv,mp3,mpegvideo,mxf,nsv,nut,ogg,rawvideo,rtp,rtsp,srt,vc1,v210,wav --disable-bsfs --enable-bsf=aac*,h264*,hevc*,mpv*,mp3*,mpeg*,vp9* \
--disable-parsers --enable-parser=aac*,ac3,flac,h263,h264,hevc,mpeg*,opus,rv*,vc1,vp8,vp9"
LIB_OPT="--enable-shared"

