make_mri() {
  echo create $1
  shift 1
  for a in $@; do
    test -f $a && echo "addlib $a"
  done
  echo save
  echo end
}

# FIXME: llvm-17 can't merge visionOS lto libs
LLVM_AR=llvm-ar-${LLVM_VER:-18}
which $LLVM_AR || LLVM_AR=llvm-ar
which $LLVM_AR || LLVM_AR=/usr/local/opt/llvm/bin/llvm-ar
which $LLVM_AR || LLVM_AR=/opt/homebrew/opt/llvm/bin/llvm-ar
which $LLVM_AR || LLVM_AR=ar
echo LLVM_AR=$LLVM_AR
echo mergea $@...
MRI=${1}.mri
make_mri $@ > $MRI
cat $MRI
${AR:=${LLVM_AR}} -M < $MRI

# ar -r: contains static libs instead of object files
# input must be thin archives(apple)
# llvm-ar -qLs $ADIR/libffmpeg.a *.a