It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki

### Download prebuilt packages

[![Totoal Downloads](https://img.shields.io/sourceforge/dt/avbuild)](https://sourceforge.net/projects/avbuild/files)


Lite build of FFmpeg master branch **(recommended)**:

[Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-master-android-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-master-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-master-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-master-linux-clang-lite.tar.xz/download), [VS2022 Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-windows-desktop-vs2022-lite.7z/download), [VS2022 UWP](https://sourceforge.net/projects/avbuild/files/uwp/ffmpeg-master-uwp-vs2022-lite.7z/download), [Clang Windows Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-windows-desktop-clang-lite.tar.xz/download)

FFmpeg releases and others: https://sourceforge.net/projects/avbuild/files

***Build Details:***

Linux, android, macOS, iOS, raspberry pi(legacy OSes), windows build:**[![Build status github](https://github.com/wang-bin/avbuild/workflows/Build/badge.svg)](https://github.com/wang-bin/avbuild/actions)** [![Build Status](https://dev.azure.com/kb137035/github/_apis/build/status/wang-bin.avbuild?branchName=master)](https://dev.azure.com/kb137035/github/_build/latest?definitionId=5&branchName=master), [CircleCI](https://circleci.com/gh/wang-bin/avbuild)

## Features

- [Support single FFmpeg shared library](tools/mklibffmpeg.sh): ffmpeg.dll, libffmpeg.so, libffmpeg.dylib, [FFmpeg.framework](tools/dylib2framework.sh)
- modern toolchain support: clang+lld, cross build for almost all platforms on any host OS
- multiple targets build and configure simultaneously
- ssl
- enable all gpu decoders and encoders if possible
- nvidia driver version is not limited(nvcuvid, nvdec, nvenc)
- ffmpeg patches
- Universal binaries for apple platforms, including apple sillicon support

## Build Matrix

| CC/H?X/OS | Linux | Android | macOS | iOS  | RPi   | Win32                          | WinStore | WinPhone |
| --------- | ----- | ------- | ----- | ---- | ----- | ------------------------------ | -------- | -------- |
| Clang     | H     | C       | A+H   | A+C  | H+C   |                                |          |          |
| Clang+LLD | H     | C       | ?     |      | A+H+C | A+H+C. <br />MINGW or VCRT120+ | A+H+C    | A+C      |
| GCC       | H     | C       | H     |      | H+C   | H+C                            |          |          |
| VS2013/15 |       |         |       |      |       | H                              | H        | C        |
| VS2017+   |       |         |       |      |       | H                              | H        |          |


- A: Apple clang
- H: host build. Clang is open source clang
- C: cross build (for example, build win32 from linux/macOS using mingw, build rpi from windows/linux/macOS using gcc and clang)
- ?: in plan
- Empty: won't support

## Fork and Custom Build by Github Actions
You can request to add your configuration. If not accepted, customize yourself and build by github actions
- Fork the repo
- Set actions variables used by workflows in github repo settings
    - FF_VER: `master`, or version, e.g. `7.0`, `6.1`
    - LINUX_SYSROOT_ID: any characters, used to update sysroot cache
    - LLVM_VER: llvm version, e.g. `20`, used by linux and windows build. Available versions can be found in https://apt.llvm.org
    - VCVER: [msvcrt](https://sourceforge.net/projects/avbuild/files/dep/msvcrt-dev.7z/download) version, e.g. `14.28.29333`. used by windows clang build
    - WINSDKVER: [windows sdk](https://sourceforge.net/projects/avbuild/files/dep/winsdk.7z/download) version, e.g. `10.0.22621.0`. used by windows clang build
    - VC_LTL_VER: VC-LTL5 version, e.g. `5.1.1`. used by windows build with LTL
- Edit workflow files(build.yml, build_gpl.yml). Remove unused jobs, e.g. sourceforge upload
- Download ffmpeg binaries from workflow artifacts

## TODO
- Azure pipeline/github action: vs2022+WSL
