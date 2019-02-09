It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki

### Download prebuilt packages

ALL: https://sourceforge.net/projects/avbuild/files

Lite build of FFmpeg release(4.1):

[Raspberry Pi](https://sourceforge.net/projects/avbuild/files/raspberry-pi/ffmpeg-4.1-raspberry-pi-clang-lite.tar.xz/download), [Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-4.1-android-clang-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-4.1-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-4.1-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-4.1-linux-gcc-lite.tar.xz/download),
[MinGW](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-4.1-desktop-MINGW-lite.7z/download), [VS2017 Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-4.1-desktop-VS2017-lite.7z/download), [UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-4.1-store-VS2017-lite.7z/download), [Clang Windows Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-4.1-windows-desktop-clang-lite.tar.xz/download), [Clang UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-4.1-windows-store-clang-lite.tar.xz/download)


Lite build of FFmpeg git:

[Raspberry Pi](https://sourceforge.net/projects/avbuild/files/raspberry-pi/ffmpeg-git-raspberry-pi-clang-lite.tar.xz/download), [Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-git-android-clang-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-git-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-git-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-git-linux-gcc-lite.tar.xz/download), 
[MinGW](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-git-desktop-MINGW-lite.7z/download), [VS2017 Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-git-desktop-VS2017-lite.7z/download), [UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-git-store-VS2017-lite.7z/download), [Clang Windows Desktop](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-git-windows-desktop-clang-lite.tar.xz/download), [Clang UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-git-windows-store-clang-lite.tar.xz/download)

***Build Details:***

Linux, android, macOS, iOS, raspberry pi, windows cross build: [![travis_ci](https://travis-ci.org/wang-bin/avbuild.svg?branch=master)](https://travis-ci.org/wang-bin/avbuild)

windows mingw, vs2013~2017, desktop/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

## Features

- multiple targets build and configure simultaneously
- ffmpeg patches
- morden toolchain support: clang+lld, cross build on any host OS
- support windows xp with latest vs and win sdk (vs2017+win10 sdk) if ffmpeg <= 3.4
- support SSL for macOS & iOS
- enable all gpu decoders and encoders if possible

## Build Matrix

| CC/H?X/OS |  Linux  |  Android  |  macOS  |   iOS   |    RPi    |  Win32  |  WinStore  | WinPhone |
|-----------|---------|-----------|---------|---------|-----------|---------|------------|----------|
|   Clang   |    H    |     X     |   A+H   |   A+X   |    H+X    |         |            |          |
| Clang+LLD |    H    |     X     |    ?    |         |   A+H+X   |  A+H+X  |   A+H+X    |     ?    |
|    GCC    |    H    |     X     |    H    |         |    H+X    |   H+X   |      ?     |     ?    |
|  VS2013   |         |           |         |         |           |    H    |      H     |     X    |
|  VS2015   |         |           |         |         |           |    H    |      H     |     X    |
|  VS2017   |         |           |         |         |           |    H    |      H     |     ?    |


- A: Apple clang
- H: host build. Clang is open source clang
- X: cross build (for example, build win32 from linux/macOS using mingw, build rpi from windows/linux/macOS using gcc and clang)
- ?: in plan
- Empty: won't support
