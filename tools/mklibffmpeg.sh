BUILD_DIR=$1

cd "$BUILD_DIR"

# TODO: win dllimport LNK4217 fix (lib.exe tt.obj /export:func /def, static lib?). also make it possible to build both static and shared lib for ffmpeg modules
if `ls libavutil/*.def &>/dev/null`; then
  echo "EXPORTS" > ffmpeg.def
  cat `find lib* -name "*.def"` |grep -vE 'EXPORTS|avpriv_' >>ffmpeg.def # mingw ld can not recognize multiple EXPORTS
  if [ -f libavutil/libavutil.dll.a ]; then
# avpriv_ are declared as av_export_avcodec/avutil, mingw link error, undefined '_imp__avpriv_mpa_freq_tab' etc.. this also results in ffmpeg can not be built both static and shared for windows
	echo "mingw ld does not support linking a single libffmpeg.dll"
	exit 0
  fi
else
  if [ -f libavutil/avutil.lib ]; then
    echo "windows static build. no need to create ffmpeg.dll"
	exit 0
  fi
fi

cat >libffmpeg.v<<EOF
LIBFFMPEG {
  global:
    av_*;
    avio_*;
    avpictuire_*;
    avsubtitle_*;
    swr_*;
    sws_*;
    avutil_*;
    avcodec_*;
    avformat_*;
    avfilter_*;
    avdevice_*;
    swresample_*;
    swscale_*;
  local:
    *;
};
EOF

function join { local IFS="$1"; shift; echo "$*"; }
# MUST remove OBJS-$(CONFIG_SHARED) OBJS-$(HAVE_LIBC_MSVCRT) in $(SUBDIR)/Makefile, which are duplicated with ones in avutil
DUP_OBJS=(libswscale/log2_tab.o libswresample/log2_tab.o libavcodec/log2_tab.o libavformat/log2_tab.o libavfilter/log2_tab.o
  libavcodec/file_open.o libavformat/file_open.o libavdevice/file_open.o
  libavformat/golomb_tab.o
  libavcodec/reverse.o libavdevice/reverse.o
  )
OBJS=`find lib* -name "*.o" |grep -vE "$(join '|' ${DUP_OBJS[@]})"`
# appveyor PATH value is very large, xargs gets error "environment is too large for exec", so use echo
OBJS=$(echo -n $OBJS)
LIBVERSION=0.0.0
RELEASE=`cat Makefile |sed 's/^include //;s/Makefile$/RELEASE/'`
[ -f $RELEASE ] && {
  LIBVERSION=`cat $RELEASE |sed 's/git/0/'`
}
LIBMAJOR=`echo $LIBVERSION |cut -d . -f 1`
LIBMINOR=`echo $LIBVERSION |cut -d . -f 2`
cat >Makefile.libffmpeg <<EOF
LIBVERSION=$LIBVERSION
LIBMAJOR=$LIBMAJOR
LIBMINOR=$LIBMINOR
OBJS=$OBJS
EOF
cat >>Makefile.libffmpeg <<'EOF'
include ffbuild/config.mak
NAME=ffmpeg
FFLIBS=avcodec avformat avfilter avdevice avutil postproc swresample swscale
FFEXTRALIBS := $(foreach lib,$(FFLIBS:%=EXTRALIBS-%),$($(lib))) $(EXTRALIBS)
ECHO   = printf "$(1)\t%s\n" $(2)
M      = @$(call ECHO,$(TAG),$@);
%.c %.h %.pc %.ver %.version: TAG = GEN

define DOBUILD
SUBDIR :=
$(SLIBNAME): $(OBJS) lib$(NAME).ver
	$$(LD) $(SHFLAGS) $(LDFLAGS) $(LDSOFLAGS) $$(LD_O) $$(filter %.o,$$^) $(FFEXTRALIBS)
	$(SLIB_EXTRA_CMD)

lib$(NAME).ver: lib$(NAME).v $(OBJS)
	$$(M)cat $$< | $(VERSION_SCRIPT_POSTPROCESS_CMD) > $$@
endef

$(eval $(call DOBUILD)) # double $$ in SHFLAGS, so need eval to expand twice
EOF

[ -f .env.sh ] && . .env.sh
make -f Makefile.libffmpeg
