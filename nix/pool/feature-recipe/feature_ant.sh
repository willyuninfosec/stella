# shellcheck shell=bash
if [ ! "$_ANT_INCLUDED_" = "1" ]; then
_ANT_INCLUDED_=1



feature_ant() {
	FEAT_NAME="ant"
	FEAT_LIST_SCHEMA="1_10_6:binary 1_9_5:binary"
	FEAT_DEFAULT_ARCH=
	FEAT_DEFAULT_FLAVOUR="binary"

	FEAT_LINK="https://ant.apache.org/"
	FEAT_DESC="Apache Ant is a Java library and command-line tool whose mission is to drive processes described in build files as targets and extension points dependent upon each other. The main known usage of Ant is the build of Java applications."
	
}

feature_ant_env() {
	ANT_HOME="${FEAT_INSTALL_ROOT}"
	export ANT_HOME="${FEAT_INSTALL_ROOT}"
}


feature_ant_1_10_6() {
	FEAT_VERSION="1_10_6"

	FEAT_BINARY_URL="http://archive.apache.org/dist/ant/binaries/apache-ant-1.10.6-bin.tar.gz"
	FEAT_BINARY_URL_FILENAME="apache-ant-1.10.6-bin.tar.gz"
	FEAT_BINARY_URL_PROTOCOL="HTTP_ZIP"

	FEAT_ENV_CALLBACK="feature_ant_env"

	FEAT_INSTALL_TEST="${FEAT_INSTALL_ROOT}"/bin/ant
	FEAT_SEARCH_PATH="${FEAT_INSTALL_ROOT}"/bin

}

feature_ant_1_9_5() {
	FEAT_VERSION="1_9_5"

	FEAT_BINARY_URL="http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.5-bin.tar.gz"
	FEAT_BINARY_URL_FILENAME="apache-ant-1.9.5-bin.tar.gz"
	FEAT_BINARY_URL_PROTOCOL="HTTP_ZIP"

	FEAT_ENV_CALLBACK="feature_ant_env"

	FEAT_INSTALL_TEST="${FEAT_INSTALL_ROOT}"/bin/ant
	FEAT_SEARCH_PATH="${FEAT_INSTALL_ROOT}"/bin

}



feature_ant_install_binary() {
	__get_resource "$FEAT_NAME" "$FEAT_BINARY_URL" "$FEAT_BINARY_URL_PROTOCOL" "$FEAT_INSTALL_ROOT" "STRIP"

}




fi
