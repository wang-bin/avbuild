
trap "echo build process $$ is about to be killed. stopping all children processes; kill -- -$$; exit 3" SIGTERM SIGINT SIGKILL
# http://stackoverflow.com/questions/392022/best-way-to-kill-all-child-processes?noredirect=1
#pkill -P $PID does not kill the grandchild:
#kill -- -$PGID kills all processes including the grandchild

OUT_DIR=sdk-ios
mkdir -p $OUT_DIR/lib
JOBS=`sysctl -n machdep.cpu.thread_count`
ARCHS=(armv7 arm64 x86_64 i386)
CONFIG_JOBS=()
for arch in ${ARCHS[@]}; do
  test -f build_${OUT_DIR}-$arch/config.txt || {
    CONFIG_JOBS=(${CONFIG_JOBS[@]} %$((${#CONFIG_JOBS[@]}+1)))
    NO_BUILD=true ./avbuild.sh ios $arch &
  }
done
[ ${#CONFIG_JOBS[@]} -gt 0 ] && {
  echo "waiting for all configure finished..."
  wait ${CONFIG_JOBS[@]}
}
echo all configuration are finished
for arch in ${ARCHS[@]}; do
  echo "building ios $arch..."
  test -d build_${OUT_DIR}-$arch && make -j$JOBS install -C build_${OUT_DIR}-$arch prefix=$PWD/${OUT_DIR}-$arch
done

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
:<<NOTE
xcrun lipo -create $(
    for a in ${ARCHS}; do
      echo -arch ${a} ${a}/lib/${libname}
    done
  ) -output universal/lib/${libname}
NOTE

done
