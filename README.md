It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki


Linux x86+x64, android, macOS, iOS, raspberry pi: [![travis_ci](https://travis-ci.org/wang-bin/avbuild.svg?branch=master)](https://travis-ci.org/wang-bin/avbuild)

windows mingw, vs2013/vs2015/vs2017, desktop/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

## Features

- configure parallism for multiple targets
- ffmpeg patches
- morden toolchain support: clang+lld

## Build Matrix

| CC/H?X/OS | Linux  |  Android  |   macOS  |   iOS   |    RPi    |  Win32  |  WinStore  | WinPhone |
|-----------|---------|-----------|----------|---------|-----------|---------|------------|----------|
|   Clang   |    H    |     X     |     H    |    X    |    H+X    |    ?    |      ?     |     ?    |
| Clang+LLD |    ?    |     ?     |     ?    |         |    ?+X    |    ?    |      ?     |     ?    |
|    GCC    |    H    |     X     |     ?    |         |    H+X    |   H+X   |      ?     |     ?    |
|  VS2013   |         |           |          |         |           |    H    |      H     |     X    |
|  VS2015   |         |           |          |         |           |    H    |      H     |     X    |
|  VS2017   |         |           |          |         |           |    H    |      H     |     ?    |


- H: host build
- X: cross build (for example, build win32 from linux/macOS using mingw, build rpi from windows/linux/macOS using gcc and clang)
- ?: in plan
- Empty: won't support

