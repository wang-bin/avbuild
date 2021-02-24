#!/bin/bash
LLVER=${LLVM_VER:-12}
NDK_HOST=linux
export XZ_OPT="--threads=`getconf _NPROCESSORS_ONLN` -9e" # -9e. -8/9 will disable mt?
  ln -sf config{${CONFIG_SUFFIX},}.sh;

git submodule update --init --recursive
if [ `which dpkg` ]; then
    #wget https://apt.llvm.org/llvm.sh
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key |sudo apt-key add -
    #sudo apt update
    #sudo apt install -y software-properties-common # for add-apt-repository, ubuntu-tooolchain-r-test is required by trusty
    sudo apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-12 main"
    sudo apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main" # clang-13
    sudo apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-8 main" # for rpi
    sudo apt update
    pkgs="sshpass nasm yasm p7zip-full lld-$LLVER clang-tools-$LLVER" # clang-tools: clang-cl
    if [ "$TARGET_OS" == "linux" ]; then
        pkgs+=" libstdc++-7-dev libxv-dev libva-dev libvdpau-dev libbz2-dev zlib1g-dev"
        if [ "$COMPILER" == "gcc" ]; then
            pkgs+=" gcc"
        fi
    elif [ "$TARGET_OS" == "sunxi" -o "$TARGET_OS" == "raspberry-pi" ]; then
        pkgs+=" binutils-arm-linux-gnueabihf"
    fi
    sudo apt install -y $pkgs
elif [ `which brew` ]; then
    pkgs="pkg-config nasm yasm perl hudochenkov/sshpass/sshpass xz p7zip"
    brew install $pkgs
    NDK_HOST=darwin
fi


wget https://sourceforge.net/projects/avbuild/files/dep/dep.7z/download -O dep.7z
7z x -y dep.7z -o/tmp &>/dev/null

if [[ "$SYSROOT_CACHE_HIT" != "true" ]]; then
  if [[ "$TARGET_OS" == "win"* || "$TARGET_OS" == "uwp"* ]]; then
    wget https://sourceforge.net/projects/avbuild/files/dep/msvcrt-dev.7z/download -O msvcrt-dev.7z
    echo 7z x msvcrt-dev.7z -o${WINDOWSSDKDIR%/?*} # VCDIR can be msvcrt-dev/120, but need to extract to msvcrt-dev
    7z x msvcrt-dev.7z -o${WINDOWSSDKDIR%/?*}
    wget https://sourceforge.net/projects/avbuild/files/dep/winsdk.7z/download -O winsdk.7z
    echo 7z x winsdk.7z -o${WINDOWSSDKDIR%/?*}
    7z x winsdk.7z -o${WINDOWSSDKDIR%/?*}
    ${WINDOWSSDKDIR}/lowercase.sh
    ${WINDOWSSDKDIR}/mkvfs.sh
  fi

  if [ "$TARGET_OS" == "sunxi" -o "$TARGET_OS" == "raspberry-pi" -o "$TARGET_OS" == "linux" ]; then
    wget https://sourceforge.net/projects/avbuild/files/${TARGET_OS}/${TARGET_OS/r*pi/rpi}-sysroot.tar.xz/download -O sysroot.tar.xz
    tar Jxf sysroot.tar.xz -C /tmp
    export SYSROOT=/tmp/sysroot
  fi
fi

ANDROID_NDK=$ANDROID_NDK_LATEST_HOME
if [ "$TARGET_OS" == "android" -a ! -d "$ANDROID_NDK_LATEST_HOME" ]; then
    ANDROID_NDK=/tmp/android-ndk
    wget https://dl.google.com/android/repository/android-ndk-${NDK_VERSION:-r22}-${NDK_HOST}-x86_64.zip -O ndk.zip
    7z x ndk.zip -o/tmp &>/dev/null
    mv /tmp/android-ndk-${NDK_VERSION:-r22} $ANDROID_NDK
fi

if [ -f ffmpeg-${FF_VERSION}/configure ]; then
  cd ffmpeg-${FF_VERSION}
  git reset --hard HEAD
  git fetch
  git checkout origin/master
  cd -
else
  FF_BRANCH=${FF_VERSION}
  [ "$FF_BRANCH" == "master" ] || FF_BRANCH="release/$FF_BRANCH"
  git clone -b ${FF_BRANCH} --depth 1 --no-tags ${FFREPO:-https://git.ffmpeg.org/ffmpeg.git} ffmpeg-${FF_VERSION}
fi

if [ -n "${CONFIG_SUFFIX}" ]; then
  ln -sf config{${CONFIG_SUFFIX},}.sh;
fi

export FFSRC=$PWD/ffmpeg-${FF_VERSION}
export ANDROID_NDK
