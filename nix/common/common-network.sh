if [ ! "$_STELLA_COMMON_NET_INCLUDED_" == "1" ]; then 
_STELLA_COMMON_NET_INCLUDED_=1


# --------------- PROXY INIT ----------------

function __init_proxy() {
	if [ -f "$STELLA_ENV_FILE" ]; then
		__get_key "$STELLA_ENV_FILE" "STELLA_PROXY" "ACTIVE" "PREFIX"
	fi

	if [ ! "$STELLA_PROXY_ACTIVE" == "" ]; then
		__get_key "$STELLA_ENV_FILE" "STELLA_PROXY_$STELLA_PROXY_ACTIVE" "PROXY_HOST" "PREFIX"
		__get_key "$STELLA_ENV_FILE" "STELLA_PROXY_$STELLA_PROXY_ACTIVE" "PROXY_PORT" "PREFIX"
		__get_key "$STELLA_ENV_FILE" "STELLA_PROXY_$STELLA_PROXY_ACTIVE" "PROXY_USER" "PREFIX"
		__get_key "$STELLA_ENV_FILE" "STELLA_PROXY_$STELLA_PROXY_ACTIVE" "PROXY_PASS" "PREFIX"

		

		eval STELLA_PROXY_HOST=$(echo '$STELLA_PROXY_'$STELLA_PROXY_ACTIVE'_PROXY_HOST')
		eval STELLA_PROXY_PORT=$(echo '$STELLA_PROXY_'$STELLA_PROXY_ACTIVE'_PROXY_PORT')
		
		eval STELLA_PROXY_USER=$(echo '$STELLA_PROXY_'$STELLA_PROXY_ACTIVE'_PROXY_USER')
		if [ "$STELLA_PROXY_USER" == "" ]; then
			STELLA_HTTP_PROXY=http://$STELLA_PROXY_HOST:$STELLA_PROXY_PORT
			STELLA_HTTPS_PROXY=http://$STELLA_PROXY_HOST:$STELLA_PROXY_PORT
		else
			eval STELLA_PROXY_PASS=$(echo '$STELLA_PROXY_'$STELLA_PROXY_ACTIVE'_PROXY_PASS')

			STELLA_HTTP_PROXY=http://$STELLA_PROXY_USER:$STELLA_PROXY_PASS@$STELLA_PROXY_HOST:$STELLA_PROXY_PORT
			STELLA_HTTPS_PROXY=http://$STELLA_PROXY_USER:$STELLA_PROXY_PASS$STELLA_PROXY_HOST:$STELLA_PROXY_PORT
		fi

		https_proxy="$STELLA_HTTPS_PROXY"
		http_proxy="$STELLA_HTTP_PROXY"
		export https_proxy="$STELLA_HTTPS_PROXY"
		export http_proxy="$STELLA_HTTP_PROXY"

		HTTPS_PROXY="$https_proxy"
		HTTP_PROXY="$http_proxy"
		export HTTPS_PROXY="$https_proxy"
		export HTTP_PROXY="$http_proxy"


		no_proxy="$STELLA_NO_PROXY"
		NO_PROXY="$STELLA_NO_PROXY"
		export no_proxy="$STELLA_NO_PROXY"
		export NO_PROXY="$STELLA_NO_PROXY"


		echo "STELLA Proxy Active : $STELLA_PROXY_ACTIVE [ $STELLA_PROXY_HOST:$STELLA_PROXY_PORT ]"
		[ ! "$STELLA_NO_PROXY" == "" ] && echo "STELLA Proxy bypassed for $STELLA_NO_PROXY"

		__proxy_override
	fi

	
}

# ---------------- SHIM FUNCTIONS -----------------------------
function __proxy_override() {

	#wget
	#use env var

	# http_proxy = http://votre_proxy:port_proxy/
	# proxy_user = votre_user_proxy
	# proxy_password = votre_mot_de_passe
	# use_proxy = on
	# wait = 15

	# sudo do not preserve env var by default
	function sudo() {
		command sudo no_proxy="$STELLA_NO_PROXY" https_proxy="$STELLA_HTTPS_PROXY" http_proxy="$STELLA_HTTP_PROXY" "$@"
	}

	function curl() {
		[ ! "$STELLA_PROXY_USER" == "" ] && echo $(command curl --noproxy $STELLA_NO_PROXY -x "$STELLA_PROXY_HOST:$STELLA_PROXY_PORT" --proxy-user "$STELLA_PROXY_USER:$STELLA_PROXY_PASS" "$@")
		[ "$STELLA_PROXY_USER" == "" ] && echo $(command curl --noproxy $STELLA_NO_PROXY -x "$STELLA_PROXY_HOST:$STELLA_PROXY_PORT" "$@")
	}


	function git() {
		no_proxy="$STELLA_NO_PROXY" https_proxy="$STELLA_HTTPS_PROXY" http_proxy="$STELLA_HTTP_PROXY" command git "$@"
	}

	function hg() {
		echo $(command hg --config http_proxy.host="$STELLA_PROXY_HOST":"$STELLA_PROXY_PORT" --config http_proxy.user="$STELLA_PROXY_USER" --config http_proxy.passwd="$STELLA_PROXY_PASS" "$@")
	}

	function mvn() {
		[ ! "$STELLA_PROXY_USER" == "" ] && command mvn -DproxyActive=true -DproxyId="$STELLA_PROXY_ACTIVE" -DproxyHost="$STELLA_PROXY_HOST" -DproxyPort="$STELLA_PROXY_PORT" -DproxyUsername="$STELLA_PROXY_USER" -DproxyPassword="$STELLA_PROXY_PASS" "$@"
		[ "$STELLA_PROXY_USER" == "" ] && command mvn -DproxyActive=true  -DproxyId="$STELLA_PROXY_ACTIVE" -DproxyHost="$STELLA_PROXY_HOST" -DproxyPort="$STELLA_PROXY_PORT" "$@"
	}

	function npm() {
		command npm --https-proxy="$STELLA_HTTPS_PROXY" --proxy="$STELLA_HTTP_PROXY" "$@"
	}

	function brew() {
		no_proxy="$STELLA_NO_PROXY" https_proxy="$STELLA_HTTPS_PROXY" http_proxy="$STELLA_HTTP_PROXY" command brew "$@"
	}



	# PROXY for DOCKER ----------

	# DOCKER DAEMON
	# Docker daemon rely on HTTP_PROXY env
	#		but the env var need to be setted in daemon environement (not client)
	#		Instead configure /etc/default/docker or /etc/sysconfig/docker and add 
	#			HTTP_PROXY="http://<proxy_host>:<proxy_port>"
	#			HTTPS_PROXY="http://<proxy_host>:<proxy_port>"
	#		Docker daemon is used when accessing docker hub (like for search, pull, ...)
	#
	# DOCKER CLIENT
	# docker client rely on HTTP_PROXY env to communicate to docker daemon via http
	#		NOTE : so you may set no-proxy env var to not use proxy when accessing daemon
	# 		eval $(docker-machine env <machine-id> --no-proxy)
	#		docker run -it ubuntu /bin/bash
	#
	# DOCKER MACHINE
	# http://stackoverflow.com/a/29303930
	# Docker machine rely on HTTP_PROXY env (ie : for download boot2docker iso)
	# How to set proxy as env var inside docker-machine (ie : HTTP_PROXY)
	# 		docker-machine create -d virtualbox --engine-env http_proxy=http://example.com:8080 --engine-env https_proxy=https://example.com:8080 --engine-env NO_PROXY=example2.com <machine-id>
	# 		WARN : This will set /var/lib/boot2docker/profile with HTTP_PROXY ONLY for docker commands (not the other commands)
	#		this file will will be used during the boot initialisation (after the automount) and before daemon start
	# How to retrieve ip of docker-machine
	# 		docker-machine ip <machine-id>
	# How to add to CURRENT no_proxy env vas ip of docker machine
	# 		eval $(docker-machine env --no-proxy <machine-id>)
	#
	# DOCKER FILE
	# into docker file, env var should be setted with ENV
	#		ENV http_proxy http://<proxy_host>:<proxy_port>

	function docker-machine() {
		if [ "$1" == "create" ]; then
			shift 1
			command docker-machine create --engine-env http_proxy="$STELLA_HTTP_PROXY" --engine-env https_proxy="$STELLA_HTTPS_PROXY" --engine-env no_proxy="$STELLA_NO_PROXY" "$@"
		else
			command docker-machine "$@"
		fi
	}

}

# -------------------- FUNCTIONS-----------------

function __register_proxy() {
	local _name=$1
	local _host=$2
	local _port=$3
	local _user=$4
	local _pass=$5

	__add_key "$STELLA_ENV_FILE" "STELLA_PROXY_$_name" "PROXY_HOST" "$_host"
	__add_key "$STELLA_ENV_FILE" "STELLA_PROXY_$_name" "PROXY_PORT" "$_port"
	__add_key "$STELLA_ENV_FILE" "STELLA_PROXY_$_name" "PROXY_USER" "$_user"
	__add_key "$STELLA_ENV_FILE" "STELLA_PROXY_$_name" "PROXY_PASS" "$_pass"
}

function __enable_proxy() {
	local _name=$1
	__add_key "$STELLA_ENV_FILE" "STELLA_PROXY" "ACTIVE" "$_name"
	__init_proxy
}

function __disable_proxy() {
	__enable_proxy
	echo "STELLA Proxy Disabled"
}

# specify IP only
function __no_proxy_for() {
	local _ip=$1
	
	[ "$STELLA_NO_PROXY" == "" ] && STELLA_NO_PROXY="$_ip"
	[ ! "$STELLA_NO_PROXY" == "" ] && STELLA_NO_PROXY="$STELLA_NO_PROXY,$_ip"

	echo "STELLA Proxy bypassed for $STELLA_NO_PROXY"

	__init_proxy
}
fi