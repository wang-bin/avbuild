
OUT_DIR=sdk-ios
mkdir -p $OUT_DIR/lib
SDK_ARCH_DIRS=$(find . -depth 1 |grep ./sdk-ios-)
echo archs: ${SDK_ARCH_DIRS//.\/sdk-ios-/}
SDK_ARCH_DIRS_A=($SDK_ARCH_DIRS)
cp -af ${SDK_ARCH_DIRS_A[0]}/include $OUT_DIR
for a in libavutil libavformat libavcodec libavfilter libavresample libavdevice libswscale libswresample; do
  libs=
  for d in $SDK_ARCH_DIRS; do
    [ -f $d/lib/${a}.a ] && libs="$libs $d/lib/${a}.a"
  done
  echo "lipo -create $libs -o $OUT_DIR/lib/${a}.a"
  test -n "$libs" && {
    lipo -create $libs -o $OUT_DIR/lib/${a}.a
    lipo -info $OUT_DIR/lib/${a}.a
  }
done
