ADIR=${1:-$PWD}
make_mri() {
  echo create $ADIR/libffmpeg.a
  for a in avutil avcodec avformat avdevice avfilter avresample swresample swscale postproc; do
    test -f $ADIR/lib${a}.a && echo "addlib $ADIR/lib${a}.a"
  done
  echo save
  echo end
}

MRI=/tmp/libffmpeg.mri
make_mri > $MRI
${AR:=ar} -M < $MRI

# llvm-ar -qLs $ADIR/libffmpeg.a *.a