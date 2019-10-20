USER_OPT="--enable-small --disable-avresample \
--disable-filters \
--enable-filter=*fade,*fifo,*format,*resample,aeval,all*,atempo,color*,convolution,draw*,eq*,framerate,*_cuda,hw*,null,scale,volume \
--disable-muxers \
--disable-encoders \
--disable-decoders \
--enable-decoder=*sub*,*text*,*web*,aac*,ac3*,alac*,ape,ass,cc_dec,cook,dca,eac3*,truehd,flv,flac,gif,h26[3-4]*,hevc*,mp[1-3]*,*peg*,mlp,mpl2,nellymoser,opus,pcm*,*png*,rawvideo,rv*,sami,srt,ssa,v210*,vc1*,vorbis,vp[6-9]*,wm*,wrapped_avframe \
--disable-demuxers \
--enable-demuxer=*sub*,*text*,*ac3,*ac,*peg*,*web*,ape,ass,avi,concat,dts*,*dash*,*flv,gif,hls,h264,hevc,kux,xv,matroska,mlv,mov,mp3,mxf,nsv,nut,ogg,pcm*,rawvideo,rt*p,spdif,srt,vc1,v210*,wav,*pipe \
--disable-parsers --enable-parser=*sub*,aac*,ac3,cook,flac,h26[3-4],hevc,m*,opus,rv*,vc1,vorbis,vp[8-9] \
$USER_OPT
"
ENC_OPT="--enable-encoder=aac,gif,h26[3-4]*,hevc*,mjpeg,mpeg[2-4]*,nellymoser,nvenc*,opus,pcm*,rawvideo,vorbis,vp*,wrapped_avframe"
MUX_OPT="--enable-muxer=dash,fifo,flv,gif,h264,hevc,hls,mjpeg,matroska*,mov,mp4,mpegts,nu*,og*,pcm*,rawvideo,spdif,wav,webm,*pipe"
ENC_OPT_MOBILE="--enable-encoder=aac,gif,h264*,nellymoser,opus,pcm*"
MUX_OPT_MOBILE="--enable-muxer=gif,hls,mov,mp4,mpegts,wav"
android_OPT="--disable-avdevice"
ios_OPT="--disable-avdevice"
rpi_OPT="--disable-avdevice"
raspberry_pi_OPT="--disable-avdevice"
sunxi_OPT="--disable-avdevice"
