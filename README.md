It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki

***Download prebuilt packages:*** https://sourceforge.net/projects/avbuild/files

***Build Details:***

Linux x86+x64, android, macOS, iOS, raspberry pi: [![travis_ci](https://travis-ci.org/wang-bin/avbuild.svg?branch=master)](https://travis-ci.org/wang-bin/avbuild)

windows mingw, vs2013/vs2015/vs2017, desktop(supports XP)/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

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

