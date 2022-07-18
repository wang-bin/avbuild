make_mri() {
  echo create $1
  shift 1
  for a in $@; do
    test -f $a && echo "addlib $a"
  done
  echo save
  echo end
}

LLVM_AR=llvm-ar-${LLVM_VER}
which $LLVM_AR || LLVM_AR=llvm-ar
which $LLVM_AR || LLVM_AR=/usr/local/opt/llvm/bin/llvm-ar
which $LLVM_AR || LLVM_AR=/opt/homebrew/opt/llvm/bin/llvm-ar
which $LLVM_AR || LLVM_AR=ar
echo LLVM_AR=$LLVM_AR
echo mergea $@...
MRI=${1}.mri
make_mri $@ > $MRI
${AR:=${LLVM_AR}} -M < $MRI

# input must be thin archives(apple)
# llvm-ar -qLs $ADIR/libffmpeg.a *.a