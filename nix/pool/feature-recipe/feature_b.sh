# shellcheck shell=bash
if [ ! "$_b_INCLUDED_" = "1" ]; then
_b_INCLUDED_=1



feature_b() {
	FEAT_NAME=b
	FEAT_LIST_SCHEMA="1_0"
	FEAT_BUNDLE="NESTED"
}

feature_b_1_0() {
	FEAT_VERSION=1_0

	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=


	# BUNDLE ITEM LIST
	# order is important
	# see http://petio.org/tools.html
	FEAT_BUNDLE_ITEM="jq ant"

	FEAT_ENV_CALLBACK=
	FEAT_BUNDLE_CALLBACK=

	FEAT_INSTALL_TEST=
	FEAT_SEARCH_PATH=


}


fi
