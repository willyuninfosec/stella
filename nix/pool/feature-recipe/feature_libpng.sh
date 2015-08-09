if [ ! "$_LIBPNG_INCLUDED_" == "1" ]; then 
_LIBPNG_INCLUDED_=1


function feature_libpng() {
	FEAT_NAME=libpng
	FEAT_LIST_SCHEMA="1_6_17:source"
	FEAT_DEFAULT_VERSION=1_6_17
	FEAT_DEFAULT_ARCH=
	FEAT_DEFAULT_FLAVOUR="source"
}

function feature_libpng_1_6_17() {
	FEAT_VERSION=1_6_17


	FEAT_SOURCE_DEPENDENCIES="zlib#1_2_8"
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=http://downloads.sourceforge.net/project/libpng/libpng16/1.6.17/libpng-1.6.17.tar.xz
	FEAT_SOURCE_URL_FILENAME=libpng-1.6.17.tar.xz
	FEAT_SOURCE_URL_PROTOCOL=HTTP_ZIP

	FEAT_BINARY_URL=
	FEAT_BINARY_URL_FILENAME=
	FEAT_BINARY_URL_PROTOCOL=

	FEAT_SOURCE_CALLBACK=feature_libpng_link
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/lib/libpng.a
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"/bin

}

function feature_libpng_link() {
	__link_feature_library "zlib#1_2_8" "" "FORCE_DYNAMIC"
}


function feature_libpng_install_source() {
	INSTALL_DIR="$FEAT_INSTALL_ROOT"
	SRC_DIR="$STELLA_APP_FEATURE_ROOT/$FEAT_NAME-$FEAT_VERSION-src"
	
	AUTO_INSTALL_CONF_FLAG_PREFIX=
	AUTO_INSTALL_CONF_FLAG_POSTFIX="--disable-dependency-tracking"
	AUTO_INSTALL_BUILD_FLAG_PREFIX=
	AUTO_INSTALL_BUILD_FLAG_POSTFIX=

	__feature_callback

	__auto_build "libpng" "$FEAT_SOURCE_URL" "$FEAT_SOURCE_URL_PROTOCOL" "$SRC_DIR" "$INSTALL_DIR" "CONFIG_TOOL configure BUILD_TOOL make"
	

	

}


fi