# shellcheck shell=bash
# shellcheck disable=2034
if [ ! "$_amazoncorretto_INCLUDED_" = "1" ]; then
_amazoncorretto_INCLUDED_=1


# Recipe for Open Java Development Kit (=JDK)

# see openjdk feature


feature_amazoncorretto() {
	FEAT_NAME="amazoncorretto"
	FEAT_LIST_SCHEMA="8_222_10_1@x64:binary 11_0_3_7_1@x64:binary"
	FEAT_DEFAULT_ARCH="x64"
	FEAT_DEFAULT_FLAVOUR="binary"
	
	FEAT_LINK="https://aws.amazon.com/corretto/"
	FEAT_DESC="Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK)."
}

feature_amazoncorretto_env() {
	export JAVA_HOME=$FEAT_INSTALL_ROOT
}



feature_amazoncorretto_8_222_10_1() {
	FEAT_VERSION="8_222_10_1"

	if [ "$STELLA_CURRENT_PLATFORM" = "linux" ]; then
		FEAT_BINARY_URL_x64="https://d3pxv6yz143wms.cloudfront.net/8.222.10.1/amazon-corretto-8.222.10.1-linux-x64.tar.gz"
		FEAT_BINARY_URL_FILENAME_x64="amazon-corretto-8.222.10.1-linux-x64.tar.gz"
		FEAT_BINARY_URL_PROTOCOL_x64="HTTP_ZIP"
	fi

	if [ "$STELLA_CURRENT_PLATFORM" = "darwin" ]; then
		FEAT_BINARY_URL_x64="https://d3pxv6yz143wms.cloudfront.net/8.222.10.1/amazon-corretto-8.222.10.1-macosx-x64.tar.gz"
		FEAT_BINARY_URL_FILENAME_x64="amazon-corretto-8.222.10.1-macosx-x64.tar.gz"
		FEAT_BINARY_URL_PROTOCOL_x64="HTTP_ZIP"
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=feature_amazoncorretto_fix_jni_header
	FEAT_ENV_CALLBACK=feature_amazoncorretto_env

	if [ "$STELLA_CURRENT_PLATFORM" = "linux" ]; then
		FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT/bin/java"
		FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT/bin"
	fi

	if [ "$STELLA_CURRENT_PLATFORM" = "darwin" ]; then
		FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT/Contents/Home/bin/java"
		FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT/Contents/Home/"
	fi
}



feature_amazoncorretto_11_0_3_7_1() {
	FEAT_VERSION="11_0_3_7_1"

	if [ "$STELLA_CURRENT_PLATFORM" = "linux" ]; then
		FEAT_BINARY_URL_x64="https://d3pxv6yz143wms.cloudfront.net/11.0.3.7.1/amazon-corretto-11.0.3.7.1-linux-x64.tar.gz"
		FEAT_BINARY_URL_FILENAME_x64="amazon-corretto-11.0.3.7.1-linux-x64.tar.gz"
		FEAT_BINARY_URL_PROTOCOL_x64="HTTP_ZIP"
	fi

	if [ "$STELLA_CURRENT_PLATFORM" = "darwin" ]; then
		FEAT_BINARY_URL_x64="https://d3pxv6yz143wms.cloudfront.net/11.0.3.7.1/amazon-corretto-11.0.3.7.1-macosx-x64.tar.gz"
		FEAT_BINARY_URL_FILENAME_x64="amazon-corretto-11.0.3.7.1-macosx-x64.tar.gz"
		FEAT_BINARY_URL_PROTOCOL_x64="HTTP_ZIP"
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=feature_amazoncorretto_fix_jni_header
	FEAT_ENV_CALLBACK=feature_amazoncorretto_env


	if [ "$STELLA_CURRENT_PLATFORM" = "linux" ]; then
		FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT/bin/java"
		FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT/bin"
	fi

	if [ "$STELLA_CURRENT_PLATFORM" = "darwin" ]; then
		FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT/Contents/Home/bin/java"
		FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT/Contents/Home/"
	fi
}




# fix problems with jni_md.h
# http://stackoverflow.com/a/24996278
feature_amazoncorretto_fix_jni_header() {
	if [ "$STELLA_CURRENT_PLATFORM" = "darwin" ]; then
		ln -s "${FEAT_INSTALL_ROOT}/Contents/Home/include/darwin/jni_md.h" "${FEAT_INSTALL_ROOT}/Contents/Home/include/jni_md.h"
		ln -s "${FEAT_INSTALL_ROOT}/Contents/Home/include/darwin/jawt_md.h" "${FEAT_INSTALL_ROOT}/Contents/Home/include/jawt_md.h"
	fi
	if [ "$STELLA_CURRENT_PLATFORM" = "linux" ]; then
		ln -s "${FEAT_INSTALL_ROOT}/Contents/Home/include/linux/jni_md.h" "${FEAT_INSTALL_ROOT}/Contents/Home/include/jni_md.h"
		ln -s "${FEAT_INSTALL_ROOT}/Contents/Home/include/linux/jawt_md.h" "${FEAT_INSTALL_ROOT}/Contents/Home/include/jawt_md.h"
	fi
}


feature_amazoncorretto_install_binary() {
	INSTALL_DIR="${FEAT_INSTALL_ROOT}"


	__get_resource "$FEAT_NAME" "$FEAT_BINARY_URL" "$FEAT_BINARY_URL_PROTOCOL" "$INSTALL_DIR" "DEST_ERASE STRIP"
	
	__feature_callback


}


fi
