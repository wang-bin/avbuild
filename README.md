It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki

### Download prebuilt packages

ALL: https://sourceforge.net/projects/avbuild/files

Lite build

[Raspberry Pi](https://sourceforge.net/projects/avbuild/files/raspberry-pi/ffmpeg-3.4.1-raspberry-pi-appleclang-lite.tar.xz/download), [Android](https://sourceforge.net/projects/avbuild/files/android/ffmpeg-3.4.1-android-clang-lite.tar.xz/download), [iOS](https://sourceforge.net/projects/avbuild/files/iOS/ffmpeg-3.4.1-iOS-lite.tar.xz/download), [macOS](https://sourceforge.net/projects/avbuild/files/macOS/ffmpeg-3.4.1-macOS-lite.tar.xz/download), [Linux](https://sourceforge.net/projects/avbuild/files/linux/ffmpeg-3.4.1-linux-gcc-lite.tar.xz/download), 

Windows Desktop [MinGW](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-3.4.1-desktop-MINGW-lite.7z/download), [VS2017](https://sourceforge.net/projects/avbuild/files/windows-desktop/ffmpeg-3.4.1-desktop-VS2017-lite.7z/download), Windows Store [UWP](https://sourceforge.net/projects/avbuild/files/windows-store/ffmpeg-3.4.1-store-VS2017-lite.7z/download)



***Build Details:***

Linux, android, macOS, iOS, raspberry pi: [![travis_ci](https://travis-ci.org/wang-bin/avbuild.svg?branch=master)](https://travis-ci.org/wang-bin/avbuild)

windows mingw, vs2013~2017, desktop/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

## Features

- multiple targets build and configure simultaneously
- ffmpeg patches
- morden toolchain support: clang+lld
- support windows xp with latest vs and win sdk (vs2017+win10 sdk) if ffmpeg <= 3.4
- support SSL for macOS & iOS

## Build Matrix

| CC/H?X/OS |  Linux  |  Android  |  macOS  |   iOS   |    RPi    |  Win32  |  WinStore  | WinPhone |
|-----------|---------|-----------|---------|---------|-----------|---------|------------|----------|
|   Clang   |    H    |     X     |   A+H   |   A+X   |    H+X    |    ?    |      ?     |     ?    |
| Clang+LLD |    H    |     ?     |    ?    |         |   A+H+X   |    ?    |      ?     |     ?    |
|    GCC    |    H    |     X     |    H    |         |    H+X    |   H+X   |      ?     |     ?    |
|  VS2013   |         |           |         |         |           |    H    |      H     |     X    |
|  VS2015   |         |           |         |         |           |    H    |      H     |     X    |
|  VS2017   |         |           |         |         |           |    H    |      H     |     ?    |


- A: Apple clang
- H: host build. Clang is open source clang
- X: cross build (for example, build win32 from linux/macOS using mingw, build rpi from windows/linux/macOS using gcc and clang)
- ?: in plan
- Empty: won't support

clang+lld to cross build for windows is currently impossible, see https://github.com/wang-bin/avbuild/wiki/Using-Clang---LLD

