# A script to convert a dylib to a framework: 'wbsecg1 at gmail.com' 2024. MIT license
gen_info_plist() {
    local name=${1##*/}
# assume multiple archs have the same version
    local VERSION=$(otool -L $1 |grep "@rpath/$name.framework/$name" |grep -v ":" |head -n 1 |sed 's,.*current version \(.*\)),\1,')
    local VERSION_SHORT=${VERSION%.*}
# minos: LC_BUILD_VERSION, since macOS10.13/iOS12.0
# version: LC_VERSION_MIN_IPHONEOS/MACOSX, old target version

    if vtool -arch arm64 -show-build $1 2>/dev/null; then
        MINOS_NEW=$(vtool -arch arm64 -show-build $1 |grep -E 'minos' |sed 's,.*minos \(.*\),\1,')
        MINOS_OLD=$(vtool -arch arm64 -show-build $1 |grep -E 'version' |sed 's,.*version \(.*\),\1,')
    elif vtool -arch x86_64 -show-build $1 2>/dev/null; then
        MINOS_NEW=$(vtool -arch x86_64 -show-build $1 |grep -E 'minos' |sed 's,.*minos \(.*\),\1,')
        MINOS_OLD=$(vtool -arch x86_64 -show-build $1 |grep -E 'version' |sed 's,.*version \(.*\),\1,')
    elif vtool -arch arm64e -show-build $1 2>/dev/null; then
        MINOS_NEW=$(vtool -arch arm64e -show-build $1 |grep -E 'minos' |sed 's,.*minos \(.*\),\1,')
        MINOS_OLD=$(vtool -arch arm64e -show-build $1 |grep -E 'version' |sed 's,.*version \(.*\),\1,')
    fi
    if ! vtool -show-build $1 |grep MACOS &>/dev/null; then
        MINOS_NODE="
    <key>MinimumOSVersion</key>
    <string>${MINOS_NEW:-$MINOS_OLD}</string>"
        PLIST=${1%/*}/Info.plist
    else
        PLIST=${1%/*}/Resources/Info.plist
    fi
    cat > $PLIST <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${name}</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>${name}</string>
	<key>CFBundleIconFile</key>
	<string></string>$MINOS_NODE
	<key>CFBundleIdentifier</key>
	<string>com.mediadevkit.${name}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION_SHORT}</string>
	<key>CSResourcesFileMapped</key>
	<true/>
</dict>
</plist>
EOF
    cp -avf PrivacyInfo.xcprivacy ${PLIST/Info.plist/}
}

# TODO: dependencies, e.g. avcodec depends on libavutil.?.dylib
dylib2fwk() {
    local dylib=$1
    local dydir=${dylib%/*}
    local name=${1##*/}
    name=${name%%.*}
    name=${name#lib}
    name=${name/ff/FF} # for ffmpeg=>FFmpeg
    local fwk=$dydir/$name.framework
    mkdir -p $fwk
    if vtool -show-build $dylib |grep MACOS &>/dev/null; then
        mkdir -p $fwk/Versions/A/Resources
        cp -avfL $dylib $fwk/Versions/A/$name
        ln -sfh A $fwk/Versions/Current
        ln -sfh Versions/Current/Resources $fwk/Resources
        ln -sf Versions/Current/$name $fwk/$name
        install_name_tool -id @rpath/$name.framework/Versions/A/$name $fwk/Versions/A/$name
        gen_info_plist $fwk/$name
    else
        cp -avfL $dylib $fwk/$name
        install_name_tool -id @rpath/$name.framework/$name $fwk/$name
        gen_info_plist $fwk/$name
    fi
}

[ $# -eq 0 ] && echo "Usage: $0 dylib_path" && exit 1
#for s in $(ls lib | grep -E '[a-z]+\.[0-9]+\.dylib'); do
dylib2fwk $1