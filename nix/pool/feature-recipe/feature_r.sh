if [ ! "$_R_INCLUDED_" == "1" ]; then 
_R_INCLUDED_=1

# TODO 
# make recipe for revolution r open (RRO) https://mran.revolutionanalytics.com/download/#download

function feature_r() {
	FEAT_NAME=r
	FEAT_LIST_SCHEMA="3_2_2:source"
	FEAT_DEFAULT_VERSION=3_2_2
	FEAT_DEFAULT_ARCH=
	FEAT_DEFAULT_FLAVOUR="source"
}




function feature_r_3_2_2() {
	FEAT_VERSION=3_2_2
	
	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=https://cran.r-project.org/src/base/R-3/R-3.2.2.tar.gz
	FEAT_SOURCE_URL_FILENAME=R-3.2.2.tar.gz
	FEAT_SOURCE_URL_PROTOCOL=HTTP_ZIP

	FEAT_BINARY_URL=
	FEAT_BINARY_URL_FILENAME=
	FEAT_BINARY_URL_PROTOCOL=

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/bin/r
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"/bin
	
}



function feature_r_install_source() {
	INSTALL_DIR="$FEAT_INSTALL_ROOT"
	SRC_DIR="$STELLA_APP_FEATURE_ROOT/$FEAT_NAME-$FEAT_VERSION-src"
	
	__get_resource "$FEAT_NAME" "$FEAT_SOURCE_URL" "$FEAT_SOURCE_URL_PROTOCOL" "$SRC_DIR" "DEST_ERASE STRIP"


	AUTO_INSTALL_CONF_FLAG_PREFIX=
	AUTO_INSTALL_CONF_FLAG_POSTFIX=
	AUTO_INSTALL_BUILD_FLAG_PREFIX=
	AUTO_INSTALL_BUILD_FLAG_POSTFIX=

	__auto_build "$FEAT_NAME" "$SRC_DIR" "$INSTALL_DIR" "CONFIG_TOOL configure BUILD_TOOL make"

}




fi