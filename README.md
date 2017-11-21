It's a tool to build ffmpeg for almost all platforms.

How: https://github.com/wang-bin/avbuild/wiki


Linux x86+x64, android, macOS, iOS, raspberry pi: [![travis_ci](https://travis-ci.org/wang-bin/avbuild.svg?branch=master)](https://travis-ci.org/wang-bin/avbuild)

windows mingw, vs2013/vs2015/vs2017, desktop/store/phone: [![appveyor_ci](https://ci.appveyor.com/api/projects/status/github/wang-bin/avbuild?branch=master&svg=true)](https://ci.appveyor.com/project/wang-bin/avbuild)

## Features

- multiple targets build and configure simultaneously
- ffmpeg patches
- morden toolchain support: clang+lld

## Build Matrix

| CC/H?X/OS |  Linux  |  Android  |  macOS  |   iOS   |    RPi    |  Win32  |  WinStore  | WinPhone |
|-----------|---------|-----------|---------|---------|-----------|---------|------------|----------|
|   Clang   |    H    |     X     |   A+H   |   A+X   |    H+X    |    ?    |      ?     |     ?    |
| Clang+LLD |    ?    |     ?     |    ?    |         |   A+H+X   |    ?    |      ?     |     ?    |
|    GCC    |    H    |     X     |    H    |         |    H+X    |   H+X   |      ?     |     ?    |
|  VS2013   |         |           |         |         |           |    H    |      H     |     X    |
|  VS2015   |         |           |         |         |           |    H    |      H     |     X    |
|  VS2017   |         |           |         |         |           |    H    |      H     |     ?    |


- A: Apple clang
- H: host build. Clang is open source clang
- X: cross build (for example, build win32 from linux/macOS using mingw, build rpi from windows/linux/macOS using gcc and clang)
- ?: in plan
- Empty: won't support

