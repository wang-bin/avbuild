# https://github.com/Nevcairiel/LAVFilters/blob/master/build_ffmpeg.sh
USER_OPT="--build-suffix=-lav --enable-small --enable-gpl --enable-avresample --disable-swresample --disable-avdevice --disable-encoders --disable-devices --disable-demuxer=matroska --disable-filters --enable-filter=scale,yadif,w3fdif --disable-protocol=async,cache,concat,httpproxy,icecast,md5,subfile --disable-muxers --enable-muxer=spdif --disable-bsfs --enable-bsf=extract_extradata,vp9_superframe_split --disable-cuda --disable-cuvid --disable-nvenc"

EXTRA_CFLAGS="-mmmx -msse4 -mfpmath=sse"
