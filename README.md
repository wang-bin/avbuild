It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki

### Download prebuilt packages



Lite build of FFmpeg master branch **(recommended)**:

[Raspberry Pi](https://sourceforge.net/projects/avbuild/files/raspberry-pi/ffmpeg-master-raspberry-pi-clang-lite.tar.xz/download), [Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-master-android-clang-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-master-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-master-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-master-linux-gcc-lite.tar.xz/download),
[MinGW](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-desktop-MINGW-lite.7z/download), [VS2019 Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-desktop-VS2019-lite.7z/download), [VS2019 UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-master-store-VS2019-lite.7z/download), [Clang Windows Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-windows-desktop-clang-lite.tar.xz/download), [Clang UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-master-windows-store-clang-lite.tar.xz/download)

FFmpeg release(4.3) and others: https://sourceforge.net/projects/avbuild/files

***Build Details:***

Linux, android, macOS, iOS, raspberry pi, windows cross build:**[![Build status github](https://github.com/wang-bin/avbuild/workflows/Build/badge.svg)](https://github.com/wang-bin/avbuild/actions)** [![Build Status](https://dev.azure.com/kb137035/github/_apis/build/status/wang-bin.avbuild?branchName=master)](https://dev.azure.com/kb137035/github/_build/latest?definitionId=5&branchName=master), [CircleCI](https://circleci.com/gh/wang-bin/avbuild)

windows mingw, vs2013~2019, desktop/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

## Features

- Support single FFmpeg shared library: ffmpeg.dll, libffmpeg.so, libffmpeg.dylib
- modern toolchain support: clang+lld, cross build for almost all platforms on any host OS
- support windows xp with latest vs and win sdk (VS2019+win10 sdk) if ffmpeg <= 3.4
- multiple targets build and configure simultaneously
- support SSL for macOS & iOS
- enable all gpu decoders and encoders if possible
- nvidia driver version is not limited(nvcuvid, nvdec, nvenc)
- ffmpeg patches
- Universal binaries for apple platforms, including apple sillicon support

## Build Matrix

| CC/H?X/OS |  Linux  |  Android  |  macOS  |   iOS   |    RPi    |  Win32  |  WinStore  | WinPhone |
|-----------|---------|-----------|---------|---------|-----------|---------|------------|----------|
|   Clang   |    H    |     C     |   A+H   |   A+C   |    H+C    |         |            |          |
| Clang+LLD |    H    |     C     |    ?    |         |   A+H+C   |  A+H+C  |   A+H+C    |    A+C   |
|    GCC    |    H    |     C     |    H    |         |    H+C    |   H+C   |            |          |
|  VS2013   |         |           |         |         |           |    H    |      H     |     C    |
|  VS2015   |         |           |         |         |           |    H    |      H     |     C    |
|  VS2017+  |         |           |         |         |           |    H    |      H     |          |


- A: Apple clang
- H: host build. Clang is open source clang
- C: cross build (for example, build win32 from linux/macOS using mingw, build rpi from windows/linux/macOS using gcc and clang)
- ?: in plan
- Empty: won't support

## TODO
- single package for windows including shared and static libs
- Azure pipeline/github action: vs2019+WSL, MinGW
