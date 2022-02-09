# A script to create libffmpeg single shared library. Author: 'wbsecg1 at gmail.com' 2019-2022. MIT license
BUILD_DIR=$1
INSTALL_DIR=$2
THIS_DIR="$(cd "$(dirname ${BASH_SOURCE[0]})";pwd -P)"

cd "$BUILD_DIR"

# TODO: win dllimport LNK4217 fix (lib.exe tt.obj /export:func /def, static lib?). also make it possible to build both static and shared lib for ffmpeg modules
if [ -f libavutil/libavutil.dll.a ]; then
# avpriv_ are declared as av_export_avcodec/avutil, mingw link error, undefined '_imp__avpriv_mpa_freq_tab' etc.. this also results in ffmpeg can not be built both static and shared for windows
  echo "mingw ld does not support linking a single ffmpeg dll"
  exit 0
fi
if ! `ls libavutil/*.def &>/dev/null`; then
  if [ -f libavutil/avutil.lib ]; then
    echo "windows static build. no need to create ffmpeg dll"
    exit 0
  fi
fi

[ -f libffmpeg.v ] || cat >libffmpeg.v<<EOF
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
  libavfilter/file_open.o
  libavformat/golomb_tab.o
  libavcodec/reverse.o libavdevice/reverse.o
  libavformat/to_upper4.o
  libavformat/dca_sample_rate_tab.o
  libavformat/ac3_channel_layout_tab.o
  libavformat/jpegtables.o
  libavformat/mpegaudiotabs.o
  libavformat/mpeg4audio_sample_rates.o
  libavformat/rangecoder_dec.o
  libavformat/jpegxl_parse.o  # what if jpegxl parser is disabled? remove 1 if both libavcodec and libavformat has jpegxl_parse.o
  libavutil/avutilres.o
  libavcodec/avcodecres.o
  libavcodec/half2float.o   # half2float.c is in libavutil, but not built into libavutil, always built in swscale
  libavcodec/vulkan.o
  libavdevice/avdeviceres.o
  libavformat/avformatres.o
  libavfilter/avfilterres.o
  libavfilter/vulkan.o
  libavresample/avresample.o
  libswscale/swscaleres.o
  libswresample/swresampleres.o
  libpostproc/postprocres.o
  )
OBJS=`find compat lib* -name "*.o" |grep -vE "$(join '|' ${DUP_OBJS[@]})"`
# appveyor PATH value is very large, xargs gets error "environment is too large for exec", so use echo
OBJS=$(echo -n $OBJS)
MAJOR_GUESS=`cat libavutil/libavutil.version |grep MAJOR |cut -d '=' -f 2`
MAJOR_GUESS=$((MAJOR_GUESS-52))
LIBVERSION=${MAJOR_GUESS}.0.0
RELEASE=`cat Makefile |sed 's/^include //;s/Makefile$/RELEASE/'`
[ -f "$RELEASE" ] && {
  RELVERSION=`cat $RELEASE |sed 's/git/0/'`
  RELMAJOR=`echo $RELVERSION |cut -d . -f 1`
  [[ "$RELMAJOR" == "$MAJOR_GUESS" ]] && LIBVERSION=$RELVERSION
}
LIBMAJOR=`echo $LIBVERSION |cut -d . -f 1`
LIBMINOR=`echo $LIBVERSION |cut -d . -f 2`
LIBMICRO=`echo $LIBVERSION |cut -d . -f 3`
test -z "$LIBMICRO" && LIBMICRO=0

sed "s,LIBFFMPEG_VERSION_MAJOR,$LIBMAJOR,g;s,LIBFFMPEG_VERSION_MINOR,$LIBMINOR,g;s,LIBFFMPEG_VERSION_MICRO,$LIBMICRO,g;s,LIBFFMPEG_VERSION,$LIBVERSION,g" "$THIS_DIR/libffmpegres.rc.in" >libffmpegres.rc

cat >libffmpeg.mk <<EOF
LIBVERSION=$LIBVERSION
LIBMAJOR=$LIBMAJOR
LIBMINOR=$LIBMINOR
OBJS=$OBJS
EOF
cat >>libffmpeg.mk <<'EOF'
include ffbuild/config.mak
NAME=ffmpeg
FFLIBS=avcodec avformat avfilter avdevice avutil postproc swresample swscale
FFEXTRALIBS := $(foreach lib,$(FFLIBS:%=EXTRALIBS-%),$($(lib))) $(EXTRALIBS)
ECHO   = printf "$(1)\t%s\n" $(2)
M      = @$(call ECHO,$(TAG),$@);
%.c %.h %.pc %.ver %.version: TAG = GEN

IFLAGS     := -I. -I$(SRC_LINK)/
vpath %.rc   $(SRC_PATH)

%.o: %.rc
	$(WINDRES) $(WINDRESFLAGS) $(IFLAGS) $(foreach ARG,$(CC_DEPFLAGS),--preprocessor-arg "$(ARG)") -o $@ $<

# Windows resource file
SLIBOBJS-$(HAVE_GNU_WINDRES)                 += lib$(NAME)res.o

define DOBUILD
SUBDIR :=
$(SUBDIR)$(SLIBNAME): $(SUBDIR)$(SLIBNAME_WITH_MAJOR)
	$(Q)cd ./$(SUBDIR) && $(LN_S) $(SLIBNAME_WITH_MAJOR) $(SLIBNAME)

$(SUBDIR)$(SLIBNAME_WITH_MAJOR): $(OBJS) $(SLIBOBJS-yes) lib$(NAME).ver
	$(SLIB_CREATE_DEF_CMD)
	$$(LD) $(SHFLAGS) $(LDFLAGS) $(LDSOFLAGS) $$(LD_O) $$(filter %.o,$$^) $(FFEXTRALIBS)
	$(SLIB_EXTRA_CMD)

lib$(NAME).ver: lib$(NAME).v $(OBJS)
	$$(M)cat $$< | $(VERSION_SCRIPT_POSTPROCESS_CMD) > $$@

install: $(SLIBNAME)
	$(Q)mkdir -p "$(SHLIBDIR)"
	$$(INSTALL) -m 755 $$< "$(SHLIBDIR)/$(SLIB_INSTALL_NAME)"
	$$(STRIP) "$(SHLIBDIR)/$(SLIB_INSTALL_NAME)"
	$(Q)$(foreach F,$(SLIB_INSTALL_LINKS),(cd "$(SHLIBDIR)" && $(LN_S) $(SLIB_INSTALL_NAME) $(F));)
	$(if $(SLIB_INSTALL_EXTRA_SHLIB),$$(INSTALL) -m 644 $(SLIB_INSTALL_EXTRA_SHLIB:%=$(SUBDIR)%) "$(SHLIBDIR)")
	$(if $(SLIB_INSTALL_EXTRA_LIB),$(Q)mkdir -p "$(LIBDIR)")
	$(if $(SLIB_INSTALL_EXTRA_LIB),$$(INSTALL) -m 644 $(SLIB_INSTALL_EXTRA_LIB:%=$(SUBDIR)%) "$(LIBDIR)")
endef

$(eval $(call DOBUILD)) # double $$ in SHFLAGS, so need eval to expand twice
EOF

[ -f .env.sh ] && . .env.sh
make -f libffmpeg.mk install prefix=$INSTALL_DIR
