#!/bin/bash
${FORCE_LTO:-false} && LTO_SUFFIX=-lto
SUFFIX=${FF_VERSION}-${TARGET_OS}
if [ -n "$COMPILER" ]; then
    SUFFIX+="-${COMPILER}"
fi

SUFFIX+=${LIB_OPT//*-/-}${CONFIG_SUFFIX}${LTO_SUFFIX}
mv sdk-* ffmpeg-${SUFFIX}
tar Jcf ffmpeg-${SUFFIX}{.tar.xz,}
ls -lh *.xz
echo "SF_USER_MAPPED: $SF_USER_MAPPED"
sshpass -p $SF_PW_MAPPED scp -o StrictHostKeyChecking=no ffmpeg-${SUFFIX}.tar.xz $SF_USER_MAPPED,avbuild@frs.sourceforge.net:/home/frs/project/a/av/avbuild/${TARGET_OS}
