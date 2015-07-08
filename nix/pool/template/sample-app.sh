#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "." )" && pwd )"
source $_CURRENT_FILE_DIR/stella-link.sh include


function usage() {
	echo "USAGE :"
	echo "----------------"
	echo "o-- foo management :"
	echo "L     foo run"
	echo "o-- general management :"
	echo "L     env install|uninstall : deploy/undeploy this app"
}

# COMMAND LINE -----------------------------------------------------------------------------------
PARAMETERS="
DOMAIN=											'domain' 			a				'foo env'
ID=												'' 					a				'install uninstall run'
"
OPTIONS="
FORCE=''				   'f'		  ''					b			0		'1'					  Force.
"
$STELLA_API argparse "$0" "$OPTIONS" "$PARAMETERS" "foo" "$(usage)" "APPARG" "$@"

#-------------------------------------------------------------------------------------------


# --------------- FOO ----------------------------
if [ "$DOMAIN" == "foo" ]; then

	if [ "$ID" == "run" ]; then
		ls
	fi
fi


# ------------- ENV ----------------------------
if [ "$DOMAIN" == "env" ]; then
	if [ "$ID" == "install" ]; then
		echo "** Install requirements"
		$STELLA_API get_features

	fi
	
	if [ "$ID" == "uninstall" ]; then
		$STELLA_API del_folder "$STELLA_APP_WORK_ROOT"
	fi

fi
