#!/bin/bash
NDK_HOST=linux
TARGET_OS=${TARGET_OS/rockchip/linux}

export XZ_OPT="--threads=`getconf _NPROCESSORS_ONLN` -9e" # -9e. -8/9 will disable mt?
  ln -sf config{${CONFIG_SUFFIX},}.sh;

git submodule update --init --recursive
pkgs="nasm yasm"
if [ "$TARGET_OS" == "wasm" ]; then
  pkgs+=" emscripten"
fi
if [ `which dpkg` ]; then
    #sudo apt-add-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main" # for rpi1
    #bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
    source /etc/os-release
    sudo add-apt-repository -y "deb http://apt.llvm.org/${VERSION_CODENAME}/ llvm-toolchain-${VERSION_CODENAME} main"
    sudo apt update
    pkgs+=" llvm-${LLVM_VER}-tools clang-${LLVM_VER} clang-tools-${LLVM_VER} clang-tidy-${LLVM_VER} lld-${LLVM_VER} libc++-${LLVM_VER}-dev libclang-rt-${LLVM_VER}-dev"
    pkgs+=" sshpass p7zip-full" # clang-tools: clang-cl
    if [ "$TARGET_OS" == "linux" ]; then
        pkgs+=" libstdc++-11-dev libxv-dev libva-dev libvdpau-dev zlib1g-dev" # link libbz2.so.1.0 on debian, but libbz2.so.1 on fedora
        if [ "$COMPILER" == "gcc" ]; then
            pkgs+=" gcc"
        fi
    elif [ "$TARGET_OS" == "windows-desktop" -o "$TARGET_OS" == "mingw" ]; then
        if [ "$COMPILER" == "gcc" ]; then
            pkgs+=" g++-mingw-w64"
        fi
    elif [ "$TARGET_OS" == "sunxi" -o "$TARGET_OS" == "raspberry-pi" ]; then
        pkgs+=" binutils-arm-linux-gnueabihf"
    fi
    sudo apt install -y $pkgs
elif [ `which brew` ]; then
    pkgs+=" hudochenkov/sshpass/sshpass llvm" # gnu-tar pkg-config perl xz p7zip"
    brew install $pkgs
    NDK_HOST=darwin
fi


wget https://sourceforge.net/projects/avbuild/files/dep/dep.7z/download -O dep.7z
7z x -y dep.7z -o/tmp
find /tmp/dep
ln -sf /tmp/dep tools/

curl -kL -o libmdk-dep.zip https://nightly.link/wang-bin/devpkgs/workflows/${DEVPKGS_WORKFLOW:=build}/main/libmdk-dep.zip
7z x -y libmdk-dep.zip -o/tmp
7z x -y /tmp/dep-av.7z -o/tmp
cp -avf /tmp/dep-av/* /tmp/dep/
ln -sfv arm64-v8a /tmp/dep/ohos/arm64
ls -l tools/dep/ohos/arm64/

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

  # https://www.libsdl.org/release/SDL2-devel-2.0.22-VC.zip
  if [ "$TARGET_OS" == "sunxi" -o "$TARGET_OS" == "raspberry-pi" -o "$TARGET_OS" == "linux" ]; then
    wget https://sourceforge.net/projects/avbuild/files/${TARGET_OS}/${TARGET_OS/r*pi/rpi}-sysroot.tar.xz/download -O sysroot.tar.xz
    tar Jxf sysroot.tar.xz -C /tmp
    export SYSROOT=/tmp/sysroot
  fi
fi

ANDROID_NDK=$ANDROID_NDK_LATEST_HOME
if [ "$TARGET_OS" == "android" -a ! -d "$ANDROID_NDK_LATEST_HOME" ]; then
    ANDROID_NDK=/tmp/android-ndk
    wget https://dl.google.com/android/repository/android-ndk-${NDK_VERSION:-r24}-${NDK_HOST}-x86_64.zip -O ndk.zip
    7z x ndk.zip -o/tmp &>/dev/null
    mv /tmp/android-ndk-${NDK_VERSION:-r24} $ANDROID_NDK
fi

FF_BRANCH=${FF_VERSION}
[ "$FF_BRANCH" == "master" ] || FF_BRANCH="release/$FF_BRANCH"
if [ -f ffmpeg-${FF_VERSION}/configure ]; then
  echo "ffmpeg src exists"
  cd ffmpeg-${FF_VERSION}
  git reset --hard HEAD
  git fetch
  git checkout origin/master
  [ -n "$FF_COMMIT" ] && git checkout $FF_COMMIT
  cd -
elif [ -n "$FF_COMMIT" ]; then
  echo "no ffmpeg src. clone and checkout $FF_COMMIT"
  git clone -b ${FF_BRANCH} ${FFREPO:-https://git.ffmpeg.org/ffmpeg.git} ffmpeg-${FF_VERSION}
  cd ffmpeg-${FF_VERSION}
  git checkout $FF_COMMIT
  cd -
else
  echo "no ffmpeg src. clone"
  git clone -b ${FF_BRANCH} --depth 1 --no-tags ${FFREPO:-https://git.ffmpeg.org/ffmpeg.git} ffmpeg-${FF_VERSION}
fi

if [ -n "${CONFIG_SUFFIX}" ]; then
  ln -sf config{${CONFIG_SUFFIX},}.sh;
fi

export FFSRC=$PWD/ffmpeg-${FF_VERSION}
export ANDROID_NDK
