if [ ! "$_EXPORTMODE_INCLUDED_" == "1" ]; then 
_EXPORTMODE_INCLUDED_=1

function feature_mode-export() {
	FEAT_NAME="mode-export"
	FEAT_LIST_SCHEMA="1"
	FEAT_DEFAULT_VERSION=1
	FEAT_DEFAULT_ARCH=

	FEAT_BUNDLE=LIST
}

function feature_mode-export_1() {
	FEAT_VERSION=1
	
	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=


	FEAT_BUNDLE_ITEM="$FEAT_MODE_EXPORT_SCHEMA"

	FEAT_ENV_CALLBACK=
	FEAT_BUNDLE_CALLBACK=

	FEAT_INSTALL_TEST=
	FEAT_SEARCH_PATH=
	
}



fi