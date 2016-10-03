if [ ! "$_DOCKERCOMPOSE_INCLUDED_" == "1" ]; then
_DOCKERCOMPOSE_INCLUDED_=1


function feature_docker-compose() {
	FEAT_NAME=docker-compose
	FEAT_LIST_SCHEMA="1_8_1@x64:binary 1_1_0@x64:binary 1_3_1@x64:binary 1_5_2@x64:binary 1_7_1@x64:binary"
	FEAT_DEFAULT_VERSION=1_7_1
	FEAT_DEFAULT_ARCH=x64
	FEAT_DEFAULT_FLAVOUR=binary
}



function feature_docker-compose_1_8_1() {
	FEAT_VERSION=1_8_1

	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=
	FEAT_SOURCE_URL_FILENAME=

	if [ "$STELLA_CURRENT_PLATFORM" == "darwin" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.8.1/docker-compose-Darwin-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Darwin-x86_64-1_8_1
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi
	if [ "$STELLA_CURRENT_PLATFORM" == "linux" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.8.1/docker-compose-Linux-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Linux-x86_64-1_8_1
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/docker-compose
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"

}

function feature_docker-compose_1_7_1() {
	FEAT_VERSION=1_7_1

	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=
	FEAT_SOURCE_URL_FILENAME=

	if [ "$STELLA_CURRENT_PLATFORM" == "darwin" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.7.1/docker-compose-Darwin-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Darwin-x86_64-1_7_1
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi
	if [ "$STELLA_CURRENT_PLATFORM" == "linux" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.7.1/docker-compose-Linux-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Linux-x86_64-1_7_1
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/docker-compose
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"

}


function feature_docker-compose_1_5_2() {
	FEAT_VERSION=1_5_2

	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=
	FEAT_SOURCE_URL_FILENAME=

	if [ "$STELLA_CURRENT_PLATFORM" == "darwin" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.5.2/docker-compose-Darwin-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Darwin-x86_64-1_5_2
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP

	fi
	if [ "$STELLA_CURRENT_PLATFORM" == "linux" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.5.2/docker-compose-Linux-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Linux-x86_64-1_5_2
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/docker-compose
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"

}




function feature_docker-compose_1_1_0() {
	FEAT_VERSION=1_1_0

	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=
	FEAT_SOURCE_URL_FILENAME=

	if [ "$STELLA_CURRENT_PLATFORM" == "darwin" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.1.0/docker-compose-Darwin-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Darwin-x86_64-1_1_0
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP

	fi
	if [ "$STELLA_CURRENT_PLATFORM" == "linux" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=

		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.1.0/docker-compose-Linux-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Linux-x86_64-1_1_0
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/docker-compose
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"

}




function feature_docker-compose_1_3_1() {
	FEAT_VERSION=1_3_1

	FEAT_SOURCE_DEPENDENCIES=
	FEAT_BINARY_DEPENDENCIES=

	FEAT_SOURCE_URL=
	FEAT_SOURCE_URL_FILENAME=

	if [ "$STELLA_CURRENT_PLATFORM" == "darwin" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=
		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.3.1/docker-compose-Darwin-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Darwin-x86_64-1_3_1
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP

	fi
	if [ "$STELLA_CURRENT_PLATFORM" == "linux" ]; then
		FEAT_BINARY_URL_x86=
		FEAT_BINARY_URL_FILENAME_x86=
		FEAT_BINARY_URL_PROTOCOL_x86=
		FEAT_BINARY_URL_x64=https://github.com/docker/compose/releases/download/1.3.1/docker-compose-Linux-x86_64
		FEAT_BINARY_URL_FILENAME_x64=docker-compose-Linux-x86_64-1_3_1
		FEAT_BINARY_URL_PROTOCOL_x64=HTTP
	fi

	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_CALLBACK=
	FEAT_ENV_CALLBACK=

	FEAT_INSTALL_TEST="$FEAT_INSTALL_ROOT"/docker-compose
	FEAT_SEARCH_PATH="$FEAT_INSTALL_ROOT"

}


function feature_docker-compose_install_binary() {

	__get_resource "$FEAT_NAME" "$FEAT_BINARY_URL" "$FEAT_BINARY_URL_PROTOCOL" "$FEAT_INSTALL_ROOT" "DEST_ERASE STRIP FORCE_NAME $FEAT_BINARY_URL_FILENAME"

	mv $FEAT_INSTALL_ROOT/$FEAT_BINARY_URL_FILENAME $FEAT_INSTALL_ROOT/docker-compose
	chmod +x $FEAT_INSTALL_ROOT/docker-compose
}


fi
