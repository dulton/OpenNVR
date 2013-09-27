
#!/bin/bash
# execute this from the current project dir;
# first arg is  absolute path to the output folder
# second arg is autogen call flag: [nogen/gen]
# thirs arg is rebuild flag: [noclean/clean]
# fourth arg is ffmpeg support flag (if it exists then moment
#    will be built without gstreamer and with ffmpeg): [ffmpeg]

set -e
set -x
OUTDIR=$1

if [ "$2" = "gen" ]
then
	AUTOGEN=1
fi

if [ "$3" = "clean" ]
then
	CLEAN=1
fi

if [ "$4" = "ffmpegbuild" ]
then
	FFBUILD=1
fi

function autogen()
{
	if [ -n "$1" ]
	then
	sh ./autogen.sh 
	fi 
}

function makeclean()
{
	if [ -n "$1" ]
	then
		make clean
	fi
}

function ffmpegrebuild()
{
	if [ -n "$1" ]
	then
		sh ./build_ffmpeg.sh
	fi
}

# check required tools 
test -e /usr/bin/java
test -e /opt/flex/bin/mxmlc
# check prerequisites
CHECK_GLIB="`pkg-config --exists glib-2.0 --print-errors`"
CHECK_XML="`pkg-config --exists libxml-2.0 --print-errors`"
CHECK_JSON="`pkg-config --exists jsoncpp --print-errors`"


if [ -n "${CHECK_GLIB}" || "${CHECK_XML}" || "${CHECK_JSON}" ]; then
    echo "Not all prerequisites were installed; ${CHECK_GLIB} ${CHECK_XML} ${CHECK_JSON} "
	exit 1
fi

# build ffmpeg

ffmpegrebuild "$FFBUILD"

# Generate projects
cd libmary
autogen "$AUTOGEN"
cd ../pargen
autogen "$AUTOGEN"
cd ../scruffy
autogen "$AUTOGEN"
cd ../mconfig
autogen "$AUTOGEN"
cd ../moment  
autogen "$AUTOGEN"
cd ../moment-ffmpeg
autogen "$AUTOGEN"
cd ../moment-nvr
autogen "$AUTOGEN"
cd ../moment-onvif
autogen "$AUTOGEN"

cd ../ctemplate-2.2
sh ./configure --prefix="${OUTDIR}/ctemplate"
make
make install


I_GLIB=`pkg-config --cflags glib-2.0`
L_GLIB=`pkg-config --libs glib-2.0`
I_XML=`pkg-config --cflags libxml-2.0`
L_XML=`pkg-config --libs libxml-2.0`
I_JSON=`pkg-config --cflags jsoncpp`
L_JSON=`pkg-config --libs jsoncpp`

export THIS_CFLAGS=""
export THIS_LIBS=""
export CFLAGS="-O2"
export CXXFLAGS="${CFLAGS}"



cd ../libmary
makeclean "$CLEAN"

sh ./configure --prefix="${OUTDIR}"
make
make install

cd ../pargen
makeclean "$CLEAN"

export THIS_CFLAGS="-I${OUTDIR}/include/libmary-1.0 ${I_GLIB}"
export THIS_LIBS="-L${OUTDIR}/lib -lmary-1.0 ${L_GLIB}"
sh ./configure --prefix="${OUTDIR}"
make
make install

cd ../scruffy
makeclean "$CLEAN"

export PATH="${OUTDIR}/bin:$PATH"

export THIS_CFLAGS="${I_GLIB} -I${OUTDIR}/include/pargen-1.0 \
	-I${OUTDIR}/include/libmary-1.0"
export THIS_LIBS="${L_GLIB} \
	-L${OUTDIR}/lib -lpargen-1.0 \
	-L${OUTDIR}/lib -lmary-1.0"
sh ./configure --prefix="${OUTDIR}"
make 
make install

cd ../mconfig
makeclean "$CLEAN"

export THIS_CFLAGS="${I_GLIB} \
	-I${OUTDIR}/include/pargen-1.0 \
	-I${OUTDIR}/include/libmary-1.0 \
	-I${OUTDIR}/include/scruffy-1.0/"
export THIS_LIBS="${L_GLIB} \
	-L${OUTDIR}/lib -lpargen-1.0 \
	-L${OUTDIR}/lib -lmary-1.0 \
	-L${OUTDIR}/lib -lscruffy-1.0"
sh ./configure --prefix="${OUTDIR}"
make
make install

cd ../moment
makeclean "$CLEAN"


export THIS_CFLAGS="-I${OUTDIR}/ctemplate/include \
	${I_GLIB} ${I_XML} ${I_JSON} \
	-I${OUTDIR}/include/pargen-1.0 \
	-I${OUTDIR}/include/libmary-1.0 \
	-I${OUTDIR}/include/scruffy-1.0 \
	-I${OUTDIR}/include/mconfig-1.0"
export THIS_LIBS="${L_GLIB} ${L_XML} ${L_JSON} \
	-L${OUTDIR}/lib -lpargen-1.0 \
	-L${OUTDIR}/lib -lmary-1.0 \
	-L${OUTDIR}/lib -lscruffy-1.0 \
	-L${OUTDIR}/lib -lmconfig-1.0 \
	-L${OUTDIR}/ctemplate/lib -lctemplate"

./configure --prefix="${OUTDIR}" --disable-gstreamer

make
make install

cd ./web
make
make install
cd ..

export THIS_CFLAGS="${I_GLIB} ${I_XML} ${I_JSON} \
	-I${OUTDIR}/include/moment-1.0 \
	-I${OUTDIR}/include/libmary-1.0 \
	-I${OUTDIR}/include/mconfig-1.0 \
	-I${OUTDIR}/include/pargen-1.0"
export THIS_LIBS="${L_GLIB} ${L_XML} ${L_JSON} \
	-L${OUTDIR}/lib -lmoment-1.0 \
	-L${OUTDIR}/lib -lmary-1.0 \
	-L${OUTDIR}/lib -lmconfig-1.0 \
	-L${OUTDIR}/lib -lpargen-1.0"


cd ../moment-ffmpeg
export THIS_CFLAGS+=" -I../../ffmpeg/ffmpeg_build/include -I../../ffmpeg/ffmpeg_build/include/libavformat"
export THIS_LIBS+=" -Wl,--whole-archive \
	../../ffmpeg/ffmpeg_build/lib/libavformat.a \
	../../ffmpeg/ffmpeg_build/lib/libavdevice.a \
	../../ffmpeg/ffmpeg_build/lib/libavcodec.a \
	../../ffmpeg/ffmpeg_build/lib/libavfilter.a \
	../../ffmpeg/ffmpeg_build/lib/libswscale.a \
	../../ffmpeg/ffmpeg_build/lib/libavutil.a \
	../../ffmpeg/ffmpeg_build/lib/libpostproc.a \
	../../ffmpeg/ffmpeg_build/lib/librtmp.a \
	../../ffmpeg/ffmpeg_build/lib/libswresample.a \
	../../ffmpeg/ffmpeg_build/lib/libx264.a \
	-Wl,--no-whole-archive -Wl,-Bsymbolic -lz -lm"

makeclean "$CLEAN"

./configure --prefix="${OUTDIR}"
make
make install

cd ../moment-nvr
makeclean "$CLEAN"

export THIS_CFLAGS="${I_GLIB} ${I_XML} \
	-I${OUTDIR}/include/moment-1.0 \
	-I${OUTDIR}/include/libmary-1.0 \
	-I${OUTDIR}/include/mconfig-1.0 \
	-I${OUTDIR}/include/pargen-1.0"
export THIS_LIBS="${L_GLIB} ${L_XML} \
	-L${OUTDIR}/lib -lmoment-1.0 \
	-L${OUTDIR}/lib -lmary-1.0 \
	-L${OUTDIR}/lib -lmconfig-1.0 \
	-L${OUTDIR}/lib -lpargen-1.0"

export THIS_CFLAGS+=" -I../../ffmpeg/ffmpeg_build/include -I../../ffmpeg/ffmpeg_build/include/libavformat"
export THIS_LIBS+=" -Wl,--whole-archive \
	../../ffmpeg/ffmpeg_build/lib/libavformat.a \
	../../ffmpeg/ffmpeg_build/lib/libavdevice.a \
	../../ffmpeg/ffmpeg_build/lib/libavcodec.a \
	../../ffmpeg/ffmpeg_build/lib/libavfilter.a \
	../../ffmpeg/ffmpeg_build/lib/libswscale.a \
	../../ffmpeg/ffmpeg_build/lib/libavutil.a \
	../../ffmpeg/ffmpeg_build/lib/libpostproc.a \
	../../ffmpeg/ffmpeg_build/lib/librtmp.a \
	../../ffmpeg/ffmpeg_build/lib/libswresample.a \
	../../ffmpeg/ffmpeg_build/lib/libx264.a \
	-Wl,--no-whole-archive -Wl,-Bsymbolic -lz -lm"

./configure --prefix="${OUTDIR}"
make
make install

cd ../moment-onvif
makeclean "$CLEAN"

export THIS_CFLAGS="${I_GLIB} ${I_XML} \
	-I${OUTDIR}/include/moment-1.0 \
	-I${OUTDIR}/include/libmary-1.0 \
	-I${OUTDIR}/include/mconfig-1.0 \
	-I${OUTDIR}/include/pargen-1.0 \
	-I../onvif-sdk/include"
export THIS_LIBS="${L_GLIB} ${L_XML} \
	-L${OUTDIR}/lib -lmoment-1.0 \
	-L${OUTDIR}/lib -lmary-1.0 \
	-L${OUTDIR}/lib -lmconfig-1.0 \
	-L${OUTDIR}/lib -lpargen-1.0"
	

if [ $(uname -m) == "x86_64" ]
then
	export THIS_LIBS+=" -L../onvif-sdk/lib/x64 -lWsDiscovery -lOnvifSDK"
else
	export THIS_LIBS+=" -L../onvif-sdk/lib/x86 -lWsDiscovery -lOnvifSDK"
fi

./configure --prefix="${OUTDIR}"
make
make install
