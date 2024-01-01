#!/bin/bash
${FORCE_LTO:-false} && LTO_SUFFIX=-lto
SUFFIX=${FF_VERSION}-${TARGET_OS}
if [ -n "$COMPILER" ]; then
    SUFFIX+="-${COMPILER}"
fi

SUFFIX+=${LIB_OPT//*-/-}${CONFIG_SUFFIX}${LTO_SUFFIX}
mv sdk-* ffmpeg-${SUFFIX}
export XZ_OPT="-T0 -9e" # -9e. -8/9 will disable mt?
TAR=tar
# brew install gnu-tar. gtar result is 1/3 much smaller, but 1/2 slower, also no hidden files(GNUSparseFile.0). T0 is 2x faster than bsdtar
which gtar && TAR=gtar
if [[ "${TARGET_OS}" == "iOS"* || "${TARGET_OS}" == "tvOS"* ]]; then
  find ffmpeg-${SUFFIX} -name "*.mri" -delete
  $TAR Jcf ffmpeg-${SUFFIX}-shared.tar.xz --exclude="*.a" ffmpeg-${SUFFIX}
  find ffmpeg-${SUFFIX} -name "*.dylib" -delete
fi
$TAR Jcf ffmpeg-${SUFFIX}{.tar.xz,}
ls -lh *.xz
[ "$GITHUB_EVENT_NAME" == "pull_request" ] && exit 0

echo "SF_USER_MAPPED: $SF_USER_MAPPED"
sshpass -p $SF_PW_MAPPED scp -o StrictHostKeyChecking=no ffmpeg-${SUFFIX}*.tar.xz $SF_USER_MAPPED,avbuild@frs.sourceforge.net:/home/frs/project/a/av/avbuild/${TARGET_OS/mingw/windows-desktop}
