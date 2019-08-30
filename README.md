It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki

### Download prebuilt packages

ALL: https://sourceforge.net/projects/avbuild/files

Lite build of FFmpeg release(4.2):

[Raspberry Pi](https://sourceforge.net/projects/avbuild/files/raspberry-pi/ffmpeg-4.2-raspberry-pi-clang-lite.tar.xz/download), [Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-4.2-android-clang-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-4.2-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-4.2-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-4.2-linux-gcc-lite.tar.xz/download),
[MinGW](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-4.2-desktop-MINGW-lite.7z/download), [VS2017 Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-4.2-desktop-VS2017-lite.7z/download), [UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-4.2-store-VS2017-lite.7z/download), [Clang Windows Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-4.2-windows-desktop-clang-lite.tar.xz/download), [Clang UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-4.2-windows-store-clang-lite.tar.xz/download)


Lite build of FFmpeg master branch:

[Raspberry Pi](https://sourceforge.net/projects/avbuild/files/raspberry-pi/ffmpeg-master-raspberry-pi-clang-lite.tar.xz/download), [Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-master-android-clang-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-master-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-master-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-master-linux-gcc-lite.tar.xz/download),
[MinGW](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-desktop-MINGW-lite.7z/download), [VS2017 Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-desktop-VS2017-lite.7z/download), [UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-master-store-VS2017-lite.7z/download), [Clang Windows Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-master-windows-desktop-clang-lite.tar.xz/download), [Clang UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-master-windows-store-clang-lite.tar.xz/download)

***Build Details:***

Linux, android, macOS, iOS, raspberry pi, windows cross build: [![travis_ci](https://travis-ci.org/wang-bin/avbuild.svg?branch=master)](https://travis-ci.org/wang-bin/avbuild), [CircleCI](https://circleci.com/gh/wang-bin/avbuild)

windows mingw, vs2013~2017, desktop/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

## Features

- Create a single FFmpeg shared library: ffmpeg.dll, libffmpeg.so, libffmpeg.dylib
- multiple targets build and configure simultaneously
- ffmpeg patches
- modern toolchain support: clang+lld, cross build for almost all platforms on any host OS
- support windows xp with latest vs and win sdk (vs2017+win10 sdk) if ffmpeg <= 3.4
- support SSL for macOS & iOS
- enable all gpu decoders and encoders if possible
- nvidia driver version is not limited(nvcuvid, nvdec, nvenc)

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
- Azure pipeline: vs2019, macOS, etc.
- lto prebuilt(shared only)
