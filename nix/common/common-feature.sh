# shellcheck shell=bash
if [ ! "$_STELLA_COMMON_FEATURE_INCLUDED_" = "1" ]; then
_STELLA_COMMON_FEATURE_INCLUDED_=1

# --------- API -------------------

# list enabled and visible features
__list_active_features() {
	echo "$FEATURE_LIST_ENABLED_VISIBLE"
}

# list all current enabled features
__list_active_features_full() {
	echo "$FEATURE_LIST_ENABLED"
}

__list_feature_version() {
	local _SCHEMA=$1

	__internal_feature_context $_SCHEMA
	echo "$(__sort_version "$FEAT_LIST_SCHEMA" "DESC SEP _")"
}


__feature_init() {
	local _SCHEMA=$1
	local _OPT="$2"
	local _opt_hidden_feature=OFF

	local o
	for o in $_OPT; do
		[ "$o" = "HIDDEN" ] && _opt_hidden_feature=ON
	done

	__internal_feature_context "$_SCHEMA"

	# check if feature is not already enabled
	if [[ ! " ${FEATURE_LIST_ENABLED[@]} " =~ " $FEAT_NAME#$FEAT_VERSION " ]]; then
		__feature_inspect "$FEAT_SCHEMA_SELECTED"

		if [ "$TEST_FEATURE" = "1" ]; then

			# parse dependencies to init them first
			local dep
			local _origin=
			local _force_origin=
			local _dependencies=
			# TODO : we init all dependencies (not relying on feature flavour)
			#	but it should be better to have FEAT_RUNTIME_DEPENDENCIES different from DEPENDENCIES while BUILDING (FEAT_SOURCE_DEPENDENCIES)
			_dependencies="${FEAT_BINARY_DEPENDENCIES} ${FEAT_SOURCE_DEPENDENCIES}"
			local _current_feat=${FEAT_SCHEMA_SELECTED}
			__push_schema_context

			for dep in $_dependencies; do
				if [ "$dep" = "FORCE_ORIGIN_STELLA" ]; then
					_force_origin="STELLA"
					continue
				fi
				if [ "$dep" = "FORCE_ORIGIN_SYSTEM" ]; then
					_force_origin="SYSTEM"
					continue
				fi

				if [ "$_force_origin" = "" ]; then
					_origin="$(__feature_choose_origin $dep)"
				else
					_origin="$_force_origin"
				fi

				if [ "$_origin" = "STELLA" ]; then
					__feature_init ${dep}
					# if some deps are missing, this might not be an error, because we have merged FEAT_SOURCE_DEPENDENCIES and FEAT_BINARY_DEPENDENCIES
					#if [ "$TEST_FEATURE" = "0" ]; then
					#	__log "DEBUG" "** ${_current_feat} dependency $dep seems can not be initialized or is not installed."
					#fi
				fi
			done
			__pop_schema_context


			FEATURE_LIST_ENABLED="$FEATURE_LIST_ENABLED $FEAT_NAME#$FEAT_VERSION"
			if [ ! "$_opt_hidden_feature" = "ON" ]; then
				FEATURE_LIST_ENABLED_VISIBLE="$FEATURE_LIST_ENABLED_VISIBLE $FEAT_NAME#$FEAT_VERSION"
			fi

			if [ ! "$FEAT_BUNDLE" = "" ]; then
				local p
				__push_schema_context

				FEAT_BUNDLE_MODE=$FEAT_BUNDLE
				FEATURE_LIST_ENABLED="$FEATURE_LIST_ENABLED [ BUNDLE:<${FEAT_BUNDLE_MODE}> "
				for p in $FEAT_BUNDLE_ITEM; do
					__internal_feature_context $p
					if [ ! "$FEAT_SEARCH_PATH" = "" ]; then
						PATH="$FEAT_SEARCH_PATH:$PATH"
					fi
					# call env call back of each bundle item
					for c in $FEAT_ENV_CALLBACK; do
						$c
					done
					FEATURE_LIST_ENABLED="$FEATURE_LIST_ENABLED $FEAT_NAME#$FEAT_VERSION"
				done
				FEATURE_LIST_ENABLED="$FEATURE_LIST_ENABLED ]"
				FEAT_BUNDLE_MODE=

				__pop_schema_context
			fi



			if [ ! "$FEAT_SEARCH_PATH" = "" ]; then
				PATH="$FEAT_SEARCH_PATH:$PATH"
			fi

			local c
			for c in $FEAT_ENV_CALLBACK; do
				$c
			done
		fi

	fi
}


__feature_add_repo() {
	local _path="$1"
	local _var_list="$2"
	
	for recipe in "$_path"/*.sh; do
		recipe=$(basename "$recipe")
		recipe=${recipe#feature_}
		recipe=${recipe%.sh}
		[ ! "$_var_list" = "" ] && eval "$_var_list=\"${!_var_list} ${recipe}\""
		eval "__STELLA_FEATURE_LIST=\"${recipe} ${__STELLA_FEATURE_LIST}\""
	done
}


# get information on feature (from catalog)
__feature_catalog_info() {
	local _SCHEMA=$1
	__internal_feature_context $_SCHEMA
}




# look for information about an installed feature
__feature_match_installed() {
	local _SCHEMA="$1"
echo __feature_match_installed _SCHEMA $_SCHEMA
	#local _tested=
	local _version_selector=
	local _version_matched=
	#local _found=
	local _found_internal=
	local _list_installed=
	local _dirname=
	if [ "$_SCHEMA" = "" ]; then
		__internal_feature_context
		return
	fi


	# we are parsing items from inside a bundle. 
	if [ ! "$FEAT_BUNDLE_MODE" = "" ]; then
		__internal_feature_context "$_SCHEMA"
	else
		# we are NOT parsing items from inside a bundle, because FEAT_BUNDLE_MODE is NOT set
		# we are parsing a single feature OR a bundle feature
		__translate_schema "$_SCHEMA" "__VAR_FEATURE_NAME" "__VAR_FEATURE_VER" "__VAR_FEATURE_ARCH" "__VAR_FEATURE_FLAVOUR"
		#[ ! "$__VAR_FEATURE_VER" = "" ] && _tested="$__VAR_FEATURE_VER"
		[ ! "$__VAR_FEATURE_VER" = "" ] && _version_selector="$__VAR_FEATURE_VER"
		[ ! "$__VAR_FEATURE_ARCH" = "" ] && _tested="$_tested"@"$__VAR_FEATURE_ARCH"


		local __test_feature_root
		case $FEAT_BUNDLE in
			# we cannot match installed version of theses kind of bundle because of their folder structure
			MERGE_LIST|LIST )
				# MERGE_LIST : [feat_bundle_name/feat files] ==> we cannot retrieve any version information
				# LIST : this bundle is just a list  ===> we cannot retrieve feat bundle name, because there is no folder with this name
				__internal_feature_context "$_SCHEMA"
				return
			;;
			NESTED|MERGE )
				# MERGE : [feat_bundle_name/feat_bundle_version/feat files]
				# NESTED : [feat_bundle_name/feat_bundle_version/feat_bundle_item_name/feat files]
				__test_feature_root="${__VAR_FEATURE_NAME}"
			;;
			PROXY )
				# PROXY : [feat_bundle_name/feat_bundle_item_version/feat files]
				__test_feature_root="${__VAR_FEATURE_NAME}"
			;;
			* )
				# standalone feature :[feat_name/feat_item_version/feat files]
				__test_feature_root="${__VAR_FEATURE_NAME}"
				# NOT a feature of type bundle, might be a single feature OR a bundle feature
			;;
		esac


		# first lookup inside app feature root
		if [ -d "$STELLA_APP_FEATURE_ROOT/$__VAR_FEATURE_NAME" ]; then
			_list_installed=
			# list all installed version
			for _f in "$STELLA_APP_FEATURE_ROOT"/"$__VAR_FEATURE_NAME"/*; do
				if [ -d "$_f" ]; then
					_dirname="$(__get_filename_from_string "$_f")"
					_list_installed="${_list_installed} ${_dirname%%@*}"
				fi
			done

			if [ ! "${_list_installed}" = "" ]; then
				if [ "${_version_selector}" = "" ]; then
					_version_matched="$(__get_last_version "${_list_installed}" "SEP _")"
				else
					_version_matched="$(__select_version_from_list "${_version_selector}" "${_list_installed}" "SEP _")"
				fi
			fi
		fi

		# second lookup inside internal feature root
		if [ "$_version_matched" = "" ]; then
			if [ ! "$STELLA_APP_FEATURE_ROOT" = "$STELLA_INTERNAL_FEATURE_ROOT" ]; then
				if [ -d "$STELLA_INTERNAL_FEATURE_ROOT/$__VAR_FEATURE_NAME" ]; then
					_list_installed=
					# list all installed version
					for _f in  "$STELLA_INTERNAL_FEATURE_ROOT"/"$__VAR_FEATURE_NAME"/*; do
						if [ -d "$_f" ]; then
							_dirname="$(__get_filename_from_string "$_f")"
							_list_installed="${_list_installed} ${_dirname%%@*}"
						fi
					done
					if [ ! "${_list_installed}" = "" ]; then
						if [ "${_version_selector}" = "" ]; then
							_version_matched="$(__get_last_version "${_list_installed}" "SEP _")"
						else
							_version_matched="$(__select_version_from_list "${_version_selector}" "${_list_installed}" "SEP _")"
						fi
					fi
				fi
			fi

			if [ ! "$_version_matched" = "" ]; then
				_found_internal=1
				_save_app_feature_root=$STELLA_APP_FEATURE_ROOT
				STELLA_APP_FEATURE_ROOT=$STELLA_INTERNAL_FEATURE_ROOT
			fi
		fi
echo _version_matched $_version_matched
		if [ ! "${_version_matched}" = "" ]; then
			
			# TODO if internal replace STELLA_APP_FEATURE_ROOT with STELLA_INTERNAL_FEATURE_ROOT
			if [ "${FEAT_BUNDLE}" = "PROXY" ]; then
				[ -f "${STELLA_APP_FEATURE_ROOT}/${_version_matched}.stella" ] && __VAR_FEATURE_NAME="$(cat "${STELLA_APP_FEATURE_ROOT}/${_version_matched}.stella")"
			fi

			# we fix the found version with the flavour of the requested schema
			if [ ! "$__VAR_FEATURE_FLAVOUR" = "" ]; then
				__internal_feature_context "${__VAR_FEATURE_NAME}#${_version_matched}:${__VAR_FEATURE_FLAVOUR}"
			else
				__internal_feature_context "${__VAR_FEATURE_NAME}#${_version_matched}"
			fi
			if [ "$_found_internal" = "1" ];then
				STELLA_APP_FEATURE_ROOT=$_save_app_feature_root
				_found_internal=0
			fi
		else
			# empty info values
			__internal_feature_context
		fi
	fi
}

# save context before calling __feature_inspect, in case we use it inside a schema context
__push_schema_context() {
	__stack_push "$TEST_FEATURE"
	__stack_push "$FEAT_SCHEMA_SELECTED"
}
# load context before calling __feature_inspect, in case we use it inside a schema context
__pop_schema_context() {
	__stack_pop FEAT_SCHEMA_SELECTED
	__internal_feature_context $FEAT_SCHEMA_SELECTED
	__stack_pop TEST_FEATURE
}


# test if a feature is installed
# AND retrieve informations based on actually installed feature into var
# PREFIX_<info>
__feature_info() {
	local SCHEMA="$1"
	local PREFIX="$2"

	eval "$PREFIX"_TEST_FEATURE=0
	eval "$PREFIX"_FEAT_INSTALL_ROOT=
	eval "$PREFIX"_FEAT_NAME=
	eval "$PREFIX"_FEAT_VERSION=
	eval "$PREFIX"_FEAT_ARCH=
	eval "$PREFIX"_FEAT_SEARCH_PATH=

	__push_schema_context
	__feature_inspect "$SCHEMA"
	if [ "$TEST_FEATURE" = "0" ]; then
		__pop_schema_context
		return
	fi
	eval "$PREFIX"_TEST_FEATURE=\"$TEST_FEATURE\"
	eval "$PREFIX"_FEAT_INSTALL_ROOT=\"$FEAT_INSTALL_ROOT\"
	eval "$PREFIX"_FEAT_NAME=\"$FEAT_NAME\"
	eval "$PREFIX"_FEAT_VERSION=\"$FEAT_VERSION\"
	eval "$PREFIX"_FEAT_ARCH=\"$FEAT_ARCH\"
	eval "$PREFIX"_FEAT_SEARCH_PATH=\"$FEAT_SEARCH_PATH\"

	__pop_schema_context
}

# test if a feature is installed
# AND retrieve informations based on actually installed feature
# OR retrieve informations from feature recipe if not installed
__feature_inspect() {
	local _SCHEMA="$1"
	TEST_FEATURE=0

	[ "$_SCHEMA" = "" ] && return
	# grab feature installed on disk and set FEAT_SCHEMA_SELECTED
	__feature_match_installed "$_SCHEMA"


	# check FEAT_INSTALL_TEST to see if correctly installed
	if [ ! "$FEAT_SCHEMA_SELECTED" = "" ]; then
		if [ ! "$FEAT_BUNDLE" = "" ]; then

			local p
			local _t=1
			__push_schema_context

			FEAT_BUNDLE_MODE="$FEAT_BUNDLE"
			for p in $FEAT_BUNDLE_ITEM; do
				TEST_FEATURE=0
				__feature_inspect $p
				[ "$TEST_FEATURE" = "0" ] && _t=0
			done
			FEAT_BUNDLE_MODE=
			__pop_schema_context

			TEST_FEATURE=$_t
			if [ "$TEST_FEATURE" = "1" ]; then
				if [ ! "$FEAT_INSTALL_TEST" = "" ]; then
					for f in $FEAT_INSTALL_TEST; do
						if [ ! -f "$f" ]; then
							TEST_FEATURE=0
						fi
					done
				fi
			fi
		else
			TEST_FEATURE=1
			for f in $FEAT_INSTALL_TEST; do
				if [ ! -f "$f" ]; then
					TEST_FEATURE=0
				fi
			done
		fi
	else
		__feature_catalog_info $_SCHEMA
	fi
}





# TODO : update FEATURE_LIST_ENABLED and FEATURE_LIST_ENABLED_VISIBLE ?
__feature_remove() {
	local _SCHEMA=$1
	local _OPT="$2"

	local o
	local _opt_internal_feature=OFF
	#local _opt_hidden_feature=OFF
	local _opt_non_declared_feature=OFF
	for o in $_OPT; do
		[ "$o" = "INTERNAL" ] && _opt_internal_feature=ON
		#[ "$o" = "HIDDEN" ] && _opt_hidden_feature=ON
		[ "$o" = "NON_DECLARED" ] && _opt_non_declared_feature=ON
	done
echo __feature_remove $_SCHEMA FEAT_INSTALL_ROOT $FEAT_INSTALL_ROOT
	__feature_inspect "$_SCHEMA"

	if [ ! "$FEAT_SCHEMA_OS_RESTRICTION" = "" ]; then
		if [ ! "$FEAT_SCHEMA_OS_RESTRICTION" = "$STELLA_CURRENT_OS" ]; then
			return
		fi
	fi


	if [ ! "$FEAT_SCHEMA_OS_EXCLUSION" = "" ]; then
		if [ "$FEAT_SCHEMA_OS_EXCLUSION" = "$STELLA_CURRENT_OS" ]; then
			return
		fi
	fi

	local _save_app_feature_root=
	if [ "$_opt_internal_feature" = "ON" ]; then
		_save_app_feature_root=$STELLA_APP_FEATURE_ROOT
		STELLA_APP_FEATURE_ROOT=$STELLA_INTERNAL_FEATURE_ROOT
		_save_app_cache_dir=$STELLA_APP_CACHE_DIR
		STELLA_APP_CACHE_DIR=$STELLA_INTERNAL_CACHE_DIR
		_save_app_temp_dir=$STELLA_APP_TEMP_DIR
		STELLA_APP_TEMP_DIR=$STELLA_INTERNAL_TEMP_DIR
	fi

	if [ ! "$_opt_non_declared_feature" = "ON" ]; then
	#if [ ! "$_opt_hidden_feature" = "ON" ]; then
		__remove_app_feature $_SCHEMA
	fi
echo __feature_remove TEST_FEATURE $TEST_FEATURE
echo __feature_remove FEAT_BUNDLE $FEAT_BUNDLE
	if [ "$TEST_FEATURE" = "1" ]; then

		if [ ! "$FEAT_BUNDLE" = "" ]; then
			__log "DEBUG" " ** Remove bundle $FEAT_NAME version $FEAT_VERSION"
			__del_folder "${FEAT_INSTALL_ROOT}"

			case $FEAT_BUNDLE in
				PROXY|MERGE_LIST|MERGE|NESTED )
					# There is nothing more than the FEAT_INSTALL_ROOT to erase
					;;

				LIST )
					__push_schema_context
					FEAT_BUNDLE_MODE="$FEAT_BUNDLE"
					local _flags=
					case $FEAT_BUNDLE_MODE in
						LIST|MERGE_LIST|NESTED|MERGE|PROXY )
							_flags="HIDDEN NON_DECLARED"
							;;
					esac

					for p in $FEAT_BUNDLE_ITEM; do
						__feature_remove $p "$_flags"
					done
					FEAT_BUNDLE_MODE=
					__pop_schema_context
					;;
			esac
			
		else
			__log "DEBUG" " ** Remove $FEAT_NAME version $FEAT_VERSION from $FEAT_INSTALL_ROOT"
			__del_folder $FEAT_INSTALL_ROOT
		fi
	fi


	if [ "$_opt_internal_feature" = "ON" ]; then
		STELLA_APP_FEATURE_ROOT=$_save_app_feature_root
		STELLA_APP_CACHE_DIR=$_save_app_cache_dir
		STELLA_APP_TEMP_DIR=$_save_app_temp_dir
	fi

}


__feature_install_list() {
	local _list=$1

	for f in $_list; do
		__feature_install $f
	done
}


__feature_choose_origin() {
	local _SCHEMA="$1"
	__translate_schema "$_SCHEMA" "_CHOOSE_ORIGIN_FEATURE_NAME"

	local _origin="STELLA"
	for u in $STELLA_FEATURE_FROM_SYSTEM; do
		[ "$u" = "$_CHOOSE_ORIGIN_FEATURE_NAME" ] && _origin="SYSTEM"
	done

	echo $_origin
}

__feature_install() {
	local _SCHEMA=$1
	local _OPT="$2"

	local o
	local _opt_internal_feature=OFF
	local _opt_hidden_feature=OFF
	local _opt_non_declared_feature=OFF
	local _opt_ignore_dep=OFF
	local _opt_force_reinstall_dep=0
	local _flag_export=OFF
	local _dir_export=
	local _export_mode=OFF
	local _flag_portable=OFF
	local _dir_portable=
	local _portable_mode=OFF

	for o in $_OPT; do
		# INTERNAL : install feature inside stella root instead of current stella app workspace
		[ "$o" = "INTERNAL" ] && _opt_internal_feature=ON && _export_mode=OFF
		# HIDDEN : this feature will not be seen in list of active features
		[ "$o" = "HIDDEN" ] && _opt_hidden_feature=ON
		# NON_DECLARED : this feature will not been auto added added to current app properties
		[ "$o" = "NON_DECLARED" ] && _opt_non_declared_feature=ON
		# DEP_FORCE : force reinstall all dependencies
		[ "$o" = "DEP_FORCE" ] && _opt_force_reinstall_dep=1
		# DEP_IGNORE : ignore installation step of all dependencies
		[ "$o" = "DEP_IGNORE" ] && _opt_ignore_dep=ON
		# EXPORT <dir> : will install feature in this specified root directory
		[ "$_flag_export" = "ON" ] && _dir_export="$o" && _export_mode=ON && _flag_export=OFF
		[ "$o" = "EXPORT" ] && _flag_export=ON
		# PORTABLE <dir> : will install feature in this specified root directory in a portable way - this folder will ship every dependencies
		[ "$_flag_portable" = "ON" ] && _dir_portable="$o" && _portable_mode=ON && _flag_portable=OFF
		[ "$o" = "PORTABLE" ] && _flag_portable=ON
	done




	# EXPORT / PORTABLE MODE ------------------------------------
	if [ "$_export_mode" = "ON" ]; then
		_opt_internal_feature=OFF
		_opt_hidden_feature=ON
		_opt_non_declared_feature=ON

		FEAT_MODE_EXPORT_SCHEMA="$_SCHEMA"
		_SCHEMA="mode-export"

		local _save_app_feature_root="$STELLA_APP_FEATURE_ROOT"
		STELLA_APP_FEATURE_ROOT="$(__rel_to_abs_path "$_dir_export")"
		_OPT="${_OPT//EXPORT/__}"
	fi

	# TODO REVIEW PORTABLE MODE
	if [ "$_portable_mode" = "ON" ]; then
		_opt_internal_feature=OFF
		_opt_hidden_feature=ON
		_opt_non_declared_feature=ON

		FEAT_MODE_EXPORT_SCHEMA="$_SCHEMA"
		_SCHEMA="mode-export"

		local _save_app_feature_root="$STELLA_APP_FEATURE_ROOT"
		STELLA_APP_FEATURE_ROOT="$(__rel_to_abs_path "$_dir_portable")"
		_OPT="${_OPT//PORTABLE/__}"

		local _save_relocate_default_mode=$STELLA_BUILD_RELOCATE_DEFAULT
		__set_build_mode_default "RELOCATE" "ON"
	fi




	local _flag=0
	local a

	__internal_feature_context "$_SCHEMA"

	if [ ! "$FEAT_SCHEMA_OS_RESTRICTION" = "" ]; then
		if [ ! "$FEAT_SCHEMA_OS_RESTRICTION" = "$STELLA_CURRENT_OS" ]; then
			__log "INFO" " $_SCHEMA cannot be installed on $STELLA_CURRENT_OS"
			return
		fi
	fi
	if [ ! "$FEAT_SCHEMA_OS_EXCLUSION" = "" ]; then
		if [ "$FEAT_SCHEMA_OS_EXCLUSION" = "$STELLA_CURRENT_OS" ]; then
			__log "INFO" " $_SCHEMA cannot be installed on $STELLA_CURRENT_OS"
			return
		fi
	fi
echo FEAT_SCHEMA_SELECTED $FEAT_SCHEMA_SELECTED
	if [ ! "$FEAT_SCHEMA_SELECTED" = "" ]; then



		local _save_app_feature_root=
		if [ "$_opt_internal_feature" = "ON" ]; then
			_save_app_feature_root=$STELLA_APP_FEATURE_ROOT
			STELLA_APP_FEATURE_ROOT=$STELLA_INTERNAL_FEATURE_ROOT
			_save_app_cache_dir=$STELLA_APP_CACHE_DIR
			STELLA_APP_CACHE_DIR=$STELLA_INTERNAL_CACHE_DIR
			_save_app_temp_dir=$STELLA_APP_TEMP_DIR
			STELLA_APP_TEMP_DIR=$STELLA_INTERNAL_TEMP_DIR
		fi

		if [ ! "$_opt_non_declared_feature" = "ON" ]; then
			__add_app_feature $_SCHEMA
		fi


		if [ "$FORCE" = "1" ]; then
			TEST_FEATURE=0
			if [ "$_export_mode" = "OFF" ]; then
				if [ "$_portable_mode" = "OFF" ]; then
				 	#	TODO : call feature remove ? 
					__del_folder $FEAT_INSTALL_ROOT
				fi
			fi
		else
			__feature_inspect "$FEAT_SCHEMA_SELECTED"
		fi

		if [ "$TEST_FEATURE" = "0" ]; then

			if [ "$_export_mode" = "OFF" ]; then
				if [ "$_portable_mode" = "OFF" ]; then
					mkdir -p "$FEAT_INSTALL_ROOT"
				fi
			fi

			# dependencies -----------------
			if [ "$_opt_ignore_dep" = "OFF" ]; then
				local dep

				local _origin=
				local _force_origin=
				local _dependencies=
				[ "$FEAT_SCHEMA_FLAVOUR" = "source" ] && _dependencies="$FEAT_SOURCE_DEPENDENCIES"
				[ "$FEAT_SCHEMA_FLAVOUR" = "binary" ] && _dependencies="$FEAT_BINARY_DEPENDENCIES"

				save_FORCE=$FORCE
				FORCE=$_opt_force_reinstall_dep

				__push_schema_context

				for dep in $_dependencies; do

					if [ "$dep" = "FORCE_ORIGIN_STELLA" ]; then
						_force_origin="STELLA"
						continue
					fi
					if [ "$dep" = "FORCE_ORIGIN_SYSTEM" ]; then
						_force_origin="SYSTEM"
						continue
					fi

					if [ "$_force_origin" = "" ]; then
						_origin="$(__feature_choose_origin $dep)"
					else
						_origin="$_force_origin"
					fi

					if [ "$_origin" = "STELLA" ]; then
						__log "INFO" "Installing dependency $dep"

						# a dependency is not added to current app properties
						__feature_install $dep "$_OPT NON_DECLARED"
						if [ "$TEST_FEATURE" = "0" ]; then
							__log "INFO" "** Error while installing dependency feature $FEAT_SCHEMA_SELECTED"
						fi

					fi
					[ "$_origin" = "SYSTEM" ] && __log "INFO" "Using dependency $dep from SYSTEM."

				done

				__pop_schema_context
				FORCE=$save_FORCE
			fi

			# bundle -----------------
			if [ ! "$FEAT_BUNDLE" = "" ]; then

				# save export/portable mode
				__stack_push "$_export_mode"
				__stack_push "$_portable_mode"

				if [ ! "$FEAT_BUNDLE_ITEM" = "" ]; then

					__push_schema_context
					FEAT_BUNDLE_MODE=$FEAT_BUNDLE

					if [ ! "$FEAT_BUNDLE_MODE" = "LIST" ]; then
						save_FORCE=$FORCE
						FORCE=0
					fi

					# should be MERGE or NESTED or LIST or MERGE_LIST or PROXY
					# NESTED : [feat_bundle_name/feat_bundle_version/feat_bundle_item_name/feat files] each item will be installed inside the bundle path (bundle_name/bundle_version) in a separate directory without feat version
					# MERGE : [feat_bundle_name/feat_bundle_version/feat files] each item will be installed in the bundle path (bundle_name/bundle_version) but without each feature name/version
					# PROXY :[feat_bundle_name/feat_bundle_item_version/feat files]  only one item will be installed in the bundle path but with feat version (bundle_name/feat_version) and without any other feature subfolder
					# LIST : this bundle is just a list of item that will be installed normally
					# MERGE_LIST : [feat_bundle_name/feat files] this bundle is a list of items that will be installed in a MERGED way (without bundle name nor version AND without each feature name/version)
					local _flags
					case $FEAT_BUNDLE_MODE in
						LIST|MERGE_LIST|NESTED|MERGE|PROXY )
							_flags="HIDDEN NON_DECLARED"
							;;
					esac


					local _item=
					for _item in $FEAT_BUNDLE_ITEM; do
						__feature_install "${_item}" "$_OPT $_flags"
					done

					if [ ! "$FEAT_BUNDLE_MODE" = "LIST" ]; then
						FORCE=$save_FORCE
					fi

					FEAT_BUNDLE_MODE=
					__pop_schema_context
				fi


				# restore export/portable mode
				__stack_pop "_portable_mode"
				__stack_pop "_export_mode"

				# automatic call of bundle's callback after installation of all items
				__feature_callback


			else

				__log "INFO" " ** Installing $FEAT_NAME version $FEAT_VERSION in $FEAT_INSTALL_ROOT"

				# NOTE : feature_callback is called from recipe itself

				[ "$FEAT_SCHEMA_FLAVOUR" = "source" ] && __start_build_session
				feature_"$FEAT_NAME"_install_"$FEAT_SCHEMA_FLAVOUR"

				if [ "${FEAT_BUNDLE_MODE}" = "PROXY" ]; then
					echo "${FEAT_NAME}" > "${FEAT_INSTALL_ROOT}/${FEAT_VERSION}.stella"
				fi

				# Sometimes current directory is lost by the system. For example when deleting source folder at the end of the install recipe
				cd "${STELLA_APP_ROOT}" || exit 1

			fi

			if [ "$_export_mode" = "OFF" ]; then
				if [ "$_portable_mode" = "OFF" ]; then
					__feature_inspect $FEAT_SCHEMA_SELECTED

					if [ "$TEST_FEATURE" = "1" ]; then
						__log "INFO" "** Feature $_SCHEMA is installed"
						__feature_init "$FEAT_SCHEMA_SELECTED" $_OPT
					else
						__log "INFO" "** Error while installing feature $FEAT_SCHEMA_SELECTED"
						#__del_folder $FEAT_INSTALL_ROOT
						# Sometimes current directory is lost by the system
						cd "${STELLA_APP_ROOT}" || exit 1
					fi
				fi
			fi
		else
			__log "INFO" "** Feature $_SCHEMA already installed"
			__feature_init "$FEAT_SCHEMA_SELECTED" $_OPT
		fi

		if [ "$_export_mode" = "ON" ]; then
			STELLA_APP_FEATURE_ROOT=$_save_app_feature_root
		fi

		if [ "$_portable_mode" = "ON" ]; then
			STELLA_APP_FEATURE_ROOT=$_save_app_feature_root
			__set_build_mode_default "RELOCATE" "$_save_relocate_default_mode"
		fi

		if [ "$_opt_internal_feature" = "ON" ]; then
			STELLA_APP_FEATURE_ROOT=$_save_app_feature_root
			STELLA_APP_CACHE_DIR=$_save_app_cache_dir
			STELLA_APP_TEMP_DIR=$_save_app_temp_dir
		fi


	else
		__log "INFO" " ** Error unknow feature $_SCHEMA"
	fi

}






# ----------- INTERNAL ----------------


__feature_init_installed() {
	local _tested_feat_name=
	local _tested_feat_ver=
	# init internal features
	# internal features are not prioritary over app features so we init them first
	if [ ! "$STELLA_APP_FEATURE_ROOT" = "$STELLA_INTERNAL_FEATURE_ROOT" ]; then

		_save_app_feature_root_init_installed=$STELLA_APP_FEATURE_ROOT
		STELLA_APP_FEATURE_ROOT=$STELLA_INTERNAL_FEATURE_ROOT


		for f in "$STELLA_INTERNAL_FEATURE_ROOT"/*; do
			if [ -d "$f" ]; then
				_tested_feat_name="$(__get_filename_from_string $f)"
				# check for official feature
				if [[ " ${__STELLA_FEATURE_LIST[@]} " =~ " ${_tested_feat_name} " ]]; then
					
					# TODO CONTINUE HERE
					for __bundle in "$f/"bundle.*.stella; do
						case $__bundle in 
							bundle.merge.stella|bundle.nested.stella )
								__init_item="$_tested_feat_name"
							;;

							bundle.proxy.stella )
							;;

							bundle.merge_list.stella|bundle.merge_list.stella )
							;;
							
							* )
								__init_item="$_tested_feat_name"
							;;

						esac

					done
					
					# for each detected version
					for v in  "$f"/*; do
						if [ -d "$v" ]; then
							_tested_feat_ver="$(__get_filename_from_string $v)"
							# TODO : internal feature (installed in stella root) should be hidden in active feature list or not ?
							#__feature_init "$_tested_feat_name#$_tested_feat_ver" "HIDDEN"
							#__feature_init "$_tested_feat_name#$_tested_feat_ver"
							__feature_init "$__init_item#$_tested_feat_ver"
						fi
					done
				fi
			fi
		done
		STELLA_APP_FEATURE_ROOT=$_save_app_feature_root_init_installed
	fi



	for f in  "$STELLA_APP_FEATURE_ROOT"/*; do

		if [ -d "$f" ]; then
			_tested_feat_name="$(__get_filename_from_string $f)"
			# check for official feature
			if [[ " ${__STELLA_FEATURE_LIST[@]} " =~ " ${_tested_feat_name} " ]]; then
				# for each detected version
				for v in  "$f"/*; do
					if [ -d "$v" ]; then
						_tested_feat_ver="$(__get_filename_from_string $v)"
						__feature_init "$_tested_feat_name#$_tested_feat_ver"
					fi
				done
			fi
		fi
	done

	__log "INFO" "** Features initialized : $FEATURE_LIST_ENABLED_VISIBLE"
}




__feature_reinit_installed() {
	FEATURE_LIST_ENABLED=
	FEATURE_LIST_ENABLED_VISIBLE=
	__feature_init_installed
}


__feature_callback() {
	local p

	if [ ! "$FEAT_BUNDLE" = "" ]; then
		for p in $FEAT_BUNDLE_CALLBACK; do
			$p
		done
	else

		if [ "$FEAT_SCHEMA_FLAVOUR" = "source" ]; then
			for p in $FEAT_SOURCE_CALLBACK; do
				$p
			done
		fi
		if [ "$FEAT_SCHEMA_FLAVOUR" = "binary" ]; then
			for p in $FEAT_BINARY_CALLBACK; do
				$p
			done
		fi
	fi
}


# set variable of a bundle proxy recipe
__feature_bundle_proxy() {
	local _feature_name="$1"

	if [ ! "${!_feature_name}" = "" ]; then
		__list_contains "${FEAT_BUNDLE_PROXY_LIST}" "${!_feature_name}"
		if [ $? -ne 0 ]; then
			__log "ERROR" "$FEAT_NAME is a proxy feature. ${!_feature_name} is not one of \"$FEAT_BUNDLE_PROXY_LIST\""; \
			exit 1;
		fi
		FEAT_BUNDLE_PROXY_SELECTED="${!_feature_name}"
	else
		FEAT_BUNDLE_PROXY_SELECTED="${FEAT_BUNDLE_PROXY_DEFAULT}" 
	fi
echo XXX $FEAT_BUNDLE_PROXY_SELECTED
	# load proxyfied feature
	local _proxy_feat_found="0"
	if [ ! -z "$STELLA_FEATURE_RECIPE_EXTRA" ]; then
		if [ -f "$STELLA_FEATURE_RECIPE_EXTRA/feature_$FEAT_BUNDLE_PROXY_SELECTED.sh" ]; then
			. "$STELLA_FEATURE_RECIPE_EXTRA/feature_$FEAT_BUNDLE_PROXY_SELECTED.sh"
			_proxy_feat_found="1"
		fi
	fi
	if [ "$_proxy_feat_found" = "0" ]; then
		if [ -f "$STELLA_FEATURE_RECIPE/feature_$FEAT_BUNDLE_PROXY_SELECTED.sh" ]; then
			. "$STELLA_FEATURE_RECIPE/feature_$FEAT_BUNDLE_PROXY_SELECTED.sh"
			_proxy_feat_found="1"
		else
			if [ -f "$STELLA_FEATURE_RECIPE_EXPERIMENTAL/feature_$FEAT_BUNDLE_PROXY_SELECTED.sh" ]; then
				. "$STELLA_FEATURE_RECIPE_EXPERIMENTAL/feature_$FEAT_BUNDLE_PROXY_SELECTED.sh"
				_proxy_feat_found="1"
			fi
		fi
	fi
	if [ "${_proxy_feat_found}" = "1" ]; then
		feature_${FEAT_BUNDLE_PROXY_SELECTED}
		# reset FEAT_NAME and FEAT_BUNDLE because they were erased by calling the feature function of the proxified item
		FEAT_NAME="${_feature_name}"
		FEAT_BUNDLE="PROXY"

		for s in ${FEAT_LIST_SCHEMA}; do
			__translate_schema "${FEAT_NAME}#${s}" "__temp_name" "__temp_ver" "__temp_arch"
			eval "feature_${__temp_name}_${__temp_ver}() { FEAT_INSTALL_TEST=; FEAT_VERSION=\"${__temp_ver}\"; [ \"${__temp_arch}\" = \"\" ] && FEAT_BUNDLE_ITEM=\"${FEAT_BUNDLE_PROXY_SELECTED}#${s}\" || FEAT_BUNDLE_ITEM_${__temp_arch}=\"${FEAT_BUNDLE_PROXY_SELECTED}#${s}\";}"
		done
	fi	
}	


# init feature context (properties, variables, ...)
__internal_feature_context() {
	local _SCHEMA="$1"

	FEAT_ARCH=

	local TMP_FEAT_SCHEMA_NAME=
	local TMP_FEAT_SCHEMA_VERSION=
	FEAT_SCHEMA_SELECTED=
	FEAT_SCHEMA_FLAVOUR=
	FEAT_SCHEMA_OS_RESTRICTION=
	FEAT_SCHEMA_OS_EXCLUSION=

	FEAT_NAME=
	FEAT_DESC=
	FEAT_LINK=
	FEAT_LIST_SCHEMA=
	#FEAT_DEFAULT_VERSION=
	FEAT_DEFAULT_ARCH=
	FEAT_DEFAULT_FLAVOUR=
	FEAT_VERSION=
	FEAT_SOURCE_URL=
	FEAT_SOURCE_URL_FILENAME=
	FEAT_SOURCE_URL_PROTOCOL=
	FEAT_SOURCE_DEPENDENCIES=
	FEAT_SOURCE_CALLBACK=
	FEAT_BINARY_URL=
	FEAT_BINARY_URL_FILENAME=
	FEAT_BINARY_URL_PROTOCOL=
	FEAT_BINARY_DEPENDENCIES=
	FEAT_BINARY_CALLBACK=
	FEAT_DEPENDENCIES=
	FEAT_INSTALL_TEST=
	FEAT_INSTALL_ROOT=
	FEAT_SEARCH_PATH=
	FEAT_ENV_CALLBACK=
	FEAT_BUNDLE_ITEM=
	FEAT_BUNDLE_CALLBACK=
	FEAT_BUNDLE=
	FEAT_BUNDLE_PROXY_DEFAULT=
	FEAT_BUNDLE_PROXY_LIST=
	FEAT_BUNDLE_PROXY_SELECTED=


	if [ "$_SCHEMA" = "" ]; then
		return
	fi

	if [ ! "$_SCHEMA" = "" ]; then
		#__select_official_schema_old "$_SCHEMA" "FEAT_SCHEMA_SELECTED" "TMP_FEAT_SCHEMA_NAME" "TMP_FEAT_SCHEMA_VERSION" "FEAT_ARCH" "FEAT_SCHEMA_FLAVOUR" "FEAT_SCHEMA_OS_RESTRICTION" "FEAT_SCHEMA_OS_EXCLUSION"
		__select_official_schema "$_SCHEMA" "FEAT_SCHEMA_SELECTED" "TMP_FEAT_SCHEMA_NAME" "TMP_FEAT_SCHEMA_VERSION" "FEAT_ARCH" "FEAT_SCHEMA_FLAVOUR" "FEAT_SCHEMA_OS_RESTRICTION" "FEAT_SCHEMA_OS_EXCLUSION"
	fi
echo __internal_feature_context FEAT_SCHEMA_SELECTED $FEAT_SCHEMA_SELECTED
	if [ ! "$FEAT_SCHEMA_SELECTED" = "" ]; then

		# set install root (FEAT_INSTALL_ROOT) for current item of a bundle
		# when FEAT_BUNDLE_MODE is setted, then we are inside a bundle, parsing an item of the bundle
		if [ "$FEAT_BUNDLE_MODE" = "" ]; then
			if [ ! "$FEAT_ARCH" = "" ]; then
				FEAT_INSTALL_ROOT="$STELLA_APP_FEATURE_ROOT"/"$TMP_FEAT_SCHEMA_NAME"/"$TMP_FEAT_SCHEMA_VERSION"@"$FEAT_ARCH"
			else
				FEAT_INSTALL_ROOT="$STELLA_APP_FEATURE_ROOT"/"$TMP_FEAT_SCHEMA_NAME"/"$TMP_FEAT_SCHEMA_VERSION"
			fi
		else

			if [ "$FEAT_BUNDLE_MODE" = "MERGE" ]; then
				FEAT_INSTALL_ROOT="$FEAT_BUNDLE_PATH"
			fi
			if [ "$FEAT_BUNDLE_MODE" = "PROXY" ]; then
				FEAT_INSTALL_ROOT="$FEAT_BUNDLE_PATH"
			fi
			if [ "$FEAT_BUNDLE_MODE" = "NESTED" ]; then
				FEAT_INSTALL_ROOT="$FEAT_BUNDLE_PATH"/"$TMP_FEAT_SCHEMA_NAME"
			fi
			if [ "$FEAT_BUNDLE_MODE" = "LIST" ]; then
				if [ ! "$FEAT_ARCH" = "" ]; then
					FEAT_INSTALL_ROOT="$STELLA_APP_FEATURE_ROOT"/"$TMP_FEAT_SCHEMA_NAME"/"$TMP_FEAT_SCHEMA_VERSION"@"$FEAT_ARCH"
				else
					FEAT_INSTALL_ROOT="$STELLA_APP_FEATURE_ROOT"/"$TMP_FEAT_SCHEMA_NAME"/"$TMP_FEAT_SCHEMA_VERSION"
				fi
			fi
			if [ "$FEAT_BUNDLE_MODE" = "MERGE_LIST" ]; then
				FEAT_INSTALL_ROOT="$FEAT_BUNDLE_PATH"
			fi
		fi

		# grab feature info
		local _feat_found="0"
		if [ ! -z "$STELLA_FEATURE_RECIPE_EXTRA" ]; then
			if [ -f "$STELLA_FEATURE_RECIPE_EXTRA/feature_$TMP_FEAT_SCHEMA_NAME.sh" ]; then
				# shellcheck disable=1090
				. "$STELLA_FEATURE_RECIPE_EXTRA/feature_$TMP_FEAT_SCHEMA_NAME.sh"
				_feat_found="1"
			fi
		fi
		if [ "$_feat_found" = "0" ]; then
			if [ -f "$STELLA_FEATURE_RECIPE/feature_$TMP_FEAT_SCHEMA_NAME.sh" ]; then
				# shellcheck disable=1090
				. "$STELLA_FEATURE_RECIPE/feature_$TMP_FEAT_SCHEMA_NAME.sh"
				_feat_found="1"
			else
				if [ -f "$STELLA_FEATURE_RECIPE_EXPERIMENTAL/feature_$TMP_FEAT_SCHEMA_NAME.sh" ]; then
					# shellcheck disable=1090
					. "$STELLA_FEATURE_RECIPE_EXPERIMENTAL/feature_$TMP_FEAT_SCHEMA_NAME.sh"
					_feat_found="1"
				fi
			fi
		fi

		if [ "$_feat_found" = "1" ]; then
			feature_$TMP_FEAT_SCHEMA_NAME
		fi

		# bundle path - determine root install path of a bundle
		# when FEAT_BUNDLE is setted, then we are on a bundle, parsing a bundle recipe
		if [ ! "$FEAT_BUNDLE" = "" ]; then
			case $FEAT_BUNDLE in
				LIST )
					FEAT_BUNDLE_PATH=
				;;
				MERGE_LIST )
					FEAT_BUNDLE_PATH="$STELLA_APP_FEATURE_ROOT"/"$TMP_FEAT_SCHEMA_NAME"
				;;

				PROXY )
					FEAT_BUNDLE_PATH="$FEAT_INSTALL_ROOT"
					__feature_bundle_proxy "$TMP_FEAT_SCHEMA_NAME"
				;;

				* )
					FEAT_BUNDLE_PATH="$FEAT_INSTALL_ROOT"
				;;
			esac
		fi

		if [ "$_feat_found" = "1" ]; then
			feature_"$TMP_FEAT_SCHEMA_NAME"_"$TMP_FEAT_SCHEMA_VERSION"
		fi

		# set url dependending on arch
		if [ ! "$FEAT_ARCH" = "" ]; then
			local _tmp="FEAT_BINARY_URL_$FEAT_ARCH"
			FEAT_BINARY_URL=${!_tmp}
			_tmp="FEAT_BINARY_URL_FILENAME_$FEAT_ARCH"
			FEAT_BINARY_URL_FILENAME=${!_tmp}
			_tmp="FEAT_BINARY_URL_PROTOCOL_$FEAT_ARCH"
			FEAT_BINARY_URL_PROTOCOL=${!_tmp}
			_tmp="FEAT_BUNDLE_ITEM_$FEAT_ARCH"
			FEAT_BUNDLE_ITEM=${!_tmp}
			_tmp="FEAT_BINARY_DEPENDENCIES_$FEAT_ARCH"
			FEAT_BINARY_DEPENDENCIES=${!_tmp}
		fi
	else
		# we grab only os option
		# TODO why we grab os option ?
		__translate_schema "$_SCHEMA" "NONE" "NONE" "NONE" "NONE" "FEAT_SCHEMA_OS_RESTRICTION" "FEAT_SCHEMA_OS_EXCLUSION"
	fi
}


# select an official schema
# pick a feature schema by filling some values with default one
# and may return split schema properties
__select_official_schema() {
	local _SCHEMA="$1"
	local _RESULT_SCHEMA="$2"

	local _VAR_FEATURE_NAME="$3"
	local _VAR_FEATURE_VER="$4"
	local _VAR_FEATURE_ARCH="$5"
	local _VAR_FEATURE_FLAVOUR="$6"
	local _VAR_FEATURE_OS_RESTRICTION="$7"
	local _VAR_FEATURE_OS_EXCLUSION="$8"

	local _FILLED_SCHEMA=


 	if [ ! "$_RESULT_SCHEMA" = "" ]; then
		eval $_RESULT_SCHEMA=
	fi

 	# __translate_schema "$_SCHEMA" "$_VAR_FEATURE_NAME" "$_VAR_FEATURE_VER" "$_VAR_FEATURE_ARCH" "$_VAR_FEATURE_FLAVOUR" "$_VAR_FEATURE_OS_RESTRICTION" "$_VAR_FEATURE_OS_EXCLUSION"
	#__translate_schema "$_SCHEMA" "$3" "$4" "$5" "$6" "$7" "$8"
	__translate_schema "$_SCHEMA" "_TR_FEATURE_NAME" "_TR_FEATURE_VER" "_TR_FEATURE_ARCH" "_TR_FEATURE_FLAVOUR" "_TR_FEATURE_OS_RESTRICTION" "_TR_FEATURE_OS_EXCLUSION"

	# local _TR_FEATURE_NAME=${!_VAR_FEATURE_NAME}
	# local _TR_FEATURE_VER=${!_VAR_FEATURE_VER}
	# local _TR_FEATURE_ARCH=${!_VAR_FEATURE_ARCH}
	# local _TR_FEATURE_FLAVOUR=${!_VAR_FEATURE_FLAVOUR}
	# local _TR_FEATURE_OS_RESTRICTION=${!_VAR_FEATURE_OS_RESTRICTION}
	# local _TR_FEATURE_OS_EXCLUSION=${!_VAR_FEATURE_OS_EXCLUSION}


	local _official=0
	if [[ " ${__STELLA_FEATURE_LIST[@]} " =~ " ${_TR_FEATURE_NAME} " ]]; then
		# grab feature info
		local _feat_found=0
		if [ ! -z "$STELLA_FEATURE_RECIPE_EXTRA" ]; then
			if [ -f "$STELLA_FEATURE_RECIPE_EXTRA/feature_$_TR_FEATURE_NAME.sh" ]; then
				. "$STELLA_FEATURE_RECIPE_EXTRA/feature_$_TR_FEATURE_NAME.sh"
				_feat_found=1
			fi
		fi
		if [ "$_feat_found" = "0" ]; then
			if [ -f "$STELLA_FEATURE_RECIPE/feature_$_TR_FEATURE_NAME.sh" ]; then
				. "$STELLA_FEATURE_RECIPE/feature_$_TR_FEATURE_NAME.sh"
				_feat_found=1
			else
				if [ -f "$STELLA_FEATURE_RECIPE_EXPERIMENTAL/feature_$_TR_FEATURE_NAME.sh" ]; then
					. "$STELLA_FEATURE_RECIPE_EXPERIMENTAL/feature_$_TR_FEATURE_NAME.sh"
					_feat_found=1
				fi
			fi
		fi

		if [ "$_feat_found" = "1" ]; then
			# load feature properties
			feature_$_TR_FEATURE_NAME
			[ "${FEAT_BUNDLE}" = "PROXY" ] && __feature_bundle_proxy "${_TR_FEATURE_NAME}"
			[ ! "$_VAR_FEATURE_NAME" = "" ] && eval $_VAR_FEATURE_NAME=${_TR_FEATURE_NAME}
		fi


		local list_version=
		local k
		local _TMP_V=
		local _TMP_A=
		local _TMP_F=

		for k in $FEAT_LIST_SCHEMA; do
			__translate_schema "${_TR_FEATURE_NAME}#${k}" "NONE" "_TMP_V" "_TMP_A" "_TMP_F"
			# there is a flavour costraint so we filter list with it
			# NOTE : we cannot use arch as constraint
			if [ ! "${_TR_FEATURE_FLAVOUR}" = "" ]; then
				[ "${_TMP_F}" = "${_TR_FEATURE_FLAVOUR}" ] && list_version="$list_version ${_TMP_V}"
			else
				list_version="$list_version ${_TMP_V}"
			fi
		done

		# there is a flavour costraint
		if [ ! "${_TR_FEATURE_FLAVOUR}" = "" ]; then
			for v in ${list}; do
				case ${v} in
					# matching version in list starting with ${selector}
					${selector}*) filtered_list="${filtered_list} ${v}";;
				esac
			done
		fi

		# select last available version by default
		if [ "${_TR_FEATURE_VER}" = "" ]; then
			# TODO use ENDING_CHAR_REVERSE for some feature in a new FIELD (like FEAT_VERSION_ORDER)
			_TR_FEATURE_VER="$(__get_last_version "$list_version" "SEP _")"
			[ ! "$_VAR_FEATURE_VER" = "" ] && eval $_VAR_FEATURE_VER=$_TR_FEATURE_VER
		else
			# find version from the list
			_TR_FEATURE_VER="$(__select_version_from_list "${_TR_FEATURE_VER}" "${list_version}" "SEP _")"
			# NOTE : if _TR_FEATURE_VER is empty here, its because we cannot find a matching version
			[ ! "$_VAR_FEATURE_VER" = "" ] && eval $_VAR_FEATURE_VER=$_TR_FEATURE_VER
		fi

		_FILLED_SCHEMA="${_TR_FEATURE_NAME}#${_TR_FEATURE_VER}"

		# ADDING OS restriction and OS exclusion
		_OS_OPTION=
		if [ ! "$_TR_FEATURE_OS_RESTRICTION" = "" ]; then
			_OS_OPTION="$_OS_OPTION/$_TR_FEATURE_OS_RESTRICTION"
			[ ! "$_VAR_FEATURE_OS_RESTRICTION" = "" ] && eval $_VAR_FEATURE_OS_RESTRICTION=$_TR_FEATURE_OS_RESTRICTION
		fi
		if [ ! "$_TR_FEATURE_OS_EXCLUSION" = "" ]; then
			_OS_OPTION="$_OS_OPTION"\\\\"$_TR_FEATURE_OS_EXCLUSION"
			[ ! "$_VAR_FEATURE_OS_EXCLUSION" = "" ] && eval $_VAR_FEATURE_OS_EXCLUSION=$_TR_FEATURE_OS_EXCLUSION
		fi



		# check schema exists
		# we already know which version to find
		# we are looking for different arch and flavour
		# if we are looking for a bundle, only arch is used. There is no flavour support for bundle
		# starting with specified ones, then with default ones, then with possible ones
		local _looking_arch
		local _looking_flavour

		if [ "$_TR_FEATURE_ARCH" = "" ]; then
			# arch could have absolutely no info specified in default value and FEAT_LIST_SCHEMA
			# so we do not have to look for any value
			case $FEAT_DEFAULT_ARCH in
				x64 ) _looking_arch="$FEAT_DEFAULT_ARCH x86"
				;;
				x86 ) _looking_arch="$FEAT_DEFAULT_ARCH x64"
				;;
			esac
		else
			_looking_arch="$_TR_FEATURE_ARCH"
		fi

		local l
		local a
		local f

		case $FEAT_BUNDLE in
			MERGE|MERGE_LIST|LIST|NESTED )
				# bundle might have arch, but no flavour, except PROXY
				# arch is not always presents in FEAT_LIST_SCHEMA and could not have default value
				if [ "$_looking_arch" = "" ]; then
					for l in $FEAT_LIST_SCHEMA; do
						if [ "${_TR_FEATURE_NAME}#${l}" = "$_FILLED_SCHEMA" ]; then
							#[ ! "$_RESULT_SCHEMA" = "" ] && _official=1
							_official=1
						fi
						[ "$_official" = "1" ] && break
					done
				else
					for a in $_looking_arch; do
						for l in $FEAT_LIST_SCHEMA; do
						echo UUUUUU ${_TR_FEATURE_NAME}\#${l} = "$_FILLED_SCHEMA"@"$a"
							if [ "${_TR_FEATURE_NAME}#${l}" = "$_FILLED_SCHEMA"@"$a" ]; then
								#[ ! "$_RESULT_SCHEMA" = "" ] && _official=1
								_official=1
							fi
							echo _official $_official
							[ "$_official" = "1" ] && break
						done
						[ "$_official" = "1" ] && break
					done
				fi
			;;

			PROXY|* )
				# flavour is always presents in FEAT_LIST_SCHEMA but not for bundle except PROXY BUNDLE
				if [ "$_TR_FEATURE_FLAVOUR" = "" ]; then
					case $FEAT_DEFAULT_FLAVOUR in
						binary ) _looking_flavour="$FEAT_DEFAULT_FLAVOUR source"
						;;
						source ) _looking_flavour="$FEAT_DEFAULT_FLAVOUR binary"
						;;
						* ) _looking_flavour="binary source"
						;;
					esac
				else
					_looking_flavour="$_TR_FEATURE_FLAVOUR"
				fi

				for f in $_looking_flavour; do
					# we do not look for any arch while searching source flavour
					# arch is not used when schema contains source,
					# only used for binary flavour
					if [ "$f" = "source" ]; then
						for l in $FEAT_LIST_SCHEMA; do
							if [ "${_TR_FEATURE_NAME}#${l}" = "$_FILLED_SCHEMA":"$f" ]; then
								#[ ! "$_RESULT_SCHEMA" = "" ] && _official=1
								_official=1
							fi
							[ "$_official" = "1" ] && break
						done
					else
						# arch is not always presents in FEAT_LIST_SCHEMA and could not have default value
						if [ "$_looking_arch" = "" ]; then
							for l in $FEAT_LIST_SCHEMA; do
								if [ "${_TR_FEATURE_NAME}#${l}" = "$_FILLED_SCHEMA":"$f" ]; then
									#[ ! "$_RESULT_SCHEMA" = "" ] && _official=1
									_official=1
								fi
								[ "$_official" = "1" ] && break
							done
						else
							for a in $_looking_arch; do
								for l in $FEAT_LIST_SCHEMA; do
									if [ "${_TR_FEATURE_NAME}#${l}" = "$_FILLED_SCHEMA"@"$a":"$f" ]; then
										#[ ! "$_RESULT_SCHEMA" = "" ] && _official=1
										_official=1
									fi
									[ "$_official" = "1" ] && break
								done
								[ "$_official" = "1" ] && break
							done
						fi
					fi
					[ "$_official" = "1" ] && break
				done
			;;
		esac


		if 	[ "$_official" = "1" ]; then
			[ ! "$a" = "" ] && _FILLED_SCHEMA="$_FILLED_SCHEMA"@"$a"
			[ ! "$f" = "" ] && _FILLED_SCHEMA="$_FILLED_SCHEMA":"$f"

			[ ! "$_VAR_FEATURE_ARCH" = "" ] && eval $_VAR_FEATURE_ARCH="$a"
			[ ! "$_VAR_FEATURE_FLAVOUR" = "" ] && eval $_VAR_FEATURE_FLAVOUR="$f"
		fi
	fi

	if [ "$_official" = "1" ]; then
		eval $_RESULT_SCHEMA=$_FILLED_SCHEMA$_OS_OPTION
		__translate_schema "${!_RESULT_SCHEMA}" "_VAR_FEATURE_NAME" "_VAR_FEATURE_VER" "_VAR_FEATURE_ARCH" "_VAR_FEATURE_FLAVOUR" "_VAR_FEATURE_OS_RESTRICTION" "_VAR_FEATURE_OS_EXCLUSION"

	else
		[ ! "$_RESULT_SCHEMA" = "" ] && eval $_RESULT_SCHEMA=
		# not official so empty split values
		[ ! "$_VAR_FEATURE_NAME" = "" ] && eval $_VAR_FEATURE_NAME=
		[ ! "$_VAR_FEATURE_VER" = "" ] && eval $_VAR_FEATURE_VER=
		[ ! "$_VAR_FEATURE_ARCH" = "" ] && eval $_VAR_FEATURE_ARCH=
		[ ! "$_VAR_FEATURE_FLAVOUR" = "" ] && eval $_VAR_FEATURE_FLAVOUR=
		[ ! "$_VAR_FEATURE_OS_RESTRICTION" = "" ] && eval $_VAR_FEATURE_OS_RESTRICTION=
		[ ! "$_VAR_FEATURE_OS_EXCLUSION" = "" ] && eval $_VAR_FEATURE_OS_EXCLUSION=
	fi
}


# split schema properties
# feature schema name[#version][@arch][:flavour][/os_restriction][\os_exclusion] in any order
#				@arch could be x86 or x64
#				:flavour could be binary or source
# example: wget/ubuntu#1_2@x86:source wget/ubuntu#1_2@x86:source\macos
__translate_schema() {
	local _tr_schema="$1"

	local _VAR_FEATURE_NAME="$2"
	local _VAR_FEATURE_VER="$3"
	local _VAR_FEATURE_ARCH="$4"
	local _VAR_FEATURE_FLAVOUR="$5"
	local _VAR_FEATURE_OS_RESTRICTION="$6"
	local _VAR_FEATURE_OS_EXCLUSION="$7"

	if [ ! "$_VAR_FEATURE_NAME" = "" ]; then
		eval $_VAR_FEATURE_NAME=
	fi
	if [ ! "$_VAR_FEATURE_VER" = "" ]; then
		eval $_VAR_FEATURE_VER=
	fi
	if [ ! "$_VAR_FEATURE_ARCH" = "" ]; then
		eval $_VAR_FEATURE_ARCH=
	fi
	if [ ! "$_VAR_FEATURE_FLAVOUR" = "" ]; then
		eval $_VAR_FEATURE_FLAVOUR=
	fi
	if [ ! "$_VAR_FEATURE_OS_RESTRICTION" = "" ]; then
		eval $_VAR_FEATURE_OS_RESTRICTION=
	fi
	if [ ! "$_VAR_FEATURE_OS_EXCLUSION" = "" ]; then
		eval $_VAR_FEATURE_OS_EXCLUSION=
	fi

	local _char=

	_char=":"
	if [ -z "${_tr_schema##*$_char*}" ]; then
		if [ ! "$_VAR_FEATURE_FLAVOUR" = "" ]; then eval $_VAR_FEATURE_FLAVOUR="$(echo $_tr_schema | sed 's,^.*:\([^/\\#@]*\).*$,\1,')"; fi
	fi

	_char="/"
	if [ -z "${_tr_schema##*$_char*}" ]; then
		if [ ! "$_VAR_FEATURE_OS_RESTRICTION" = "" ]; then eval $_VAR_FEATURE_OS_RESTRICTION="$(echo $_tr_schema | sed 's,^.*/\([^:\\#@]*\).*$,\1,')"; fi
	fi

	_char='\\'
	if [ -z "${_tr_schema##*\\*}" ]; then
		if [ ! "$_VAR_FEATURE_OS_EXCLUSION" = "" ]; then eval $_VAR_FEATURE_OS_EXCLUSION="$(echo $_tr_schema | sed 's,^.*\\\([^:/#@]*\).*$,\1,')"; fi
	fi

	_char="#"
	if [ -z "${_tr_schema##*$_char*}" ]; then
		# NOTE : we escape < char while eval
		if [ ! "$_VAR_FEATURE_VER" = "" ]; then eval $_VAR_FEATURE_VER="$(echo $_tr_schema | sed -e 's,^.*#\([^:/\\@]*\).*$,\1,'  -e 's,<,\\<,')"; fi
	fi

	_char="@"
	if [ -z "${_tr_schema##*$_char*}" ]; then
		if [ ! "$_VAR_FEATURE_ARCH" = "" ]; then eval $_VAR_FEATURE_ARCH="$(echo $_tr_schema | sed 's,^.*@\([^:/\\#]*\).*$,\1,')"; fi
	fi


	if [ ! "$_VAR_FEATURE_NAME" = "" ]; then eval $_VAR_FEATURE_NAME="$(echo $_tr_schema | sed 's,^\([^:/\\#@]*\).*$,\1,')"; fi

	# Debug log
	#echo TRANSLATE RESULT NAME: $_VAR_FEATURE_NAME = $(eval echo \$${_VAR_FEATURE_NAME})  VERSION: $_VAR_FEATURE_VER = $(eval echo \$${_VAR_FEATURE_VER}) ARCH: $_VAR_FEATURE_ARCH = $(eval echo \$${_VAR_FEATURE_ARCH}) FLAVOUR: $_VAR_FEATURE_FLAVOUR = $(eval echo \$${_VAR_FEATURE_FLAVOUR}) OSR: $_VAR_FEATURE_OS_RESTRICTION = $(eval echo \$${_VAR_FEATURE_OS_RESTRICTION})
}


# --------------- DEPRECATED ---------------------------------------------


__file5() {
	URL=ftp://ftp.astron.com/pub/file/file-5.15.tar.gz
	VER=5.15
	FILE_NAME=file-5.15.tar.gz
	INSTALL_DIR="$STELLA_APP_FEATURE_ROOT/cross-tools"
	SRC_DIR="$STELLA_APP_FEATURE_ROOT/file-$VER-src"
	BUILD_DIR="$STELLA_APP_FEATURE_ROOT/file-$VER-build"

	AUTO_INSTALL_FLAG_PREFIX=
	AUTO_INSTALL_FLAG_POSTFIX="--disable-static"

	__auto_build "configure" "file" "$FILE_NAME" "$URL" "$SRC_DIR" "$BUILD_DIR" "$INSTALL_DIR" "STRIP"

}



# __binutils() {
# 	#TODO configure flag
# 	URL=http://ftp.gnu.org/gnu/binutils/binutils-2.23.2.tar.bz2
# 	VER=2.23.2
# 	FILE_NAME=binutils-2.23.2.tar.bz2
# 	INSTALL_DIR="$STELLA_APP_FEATURE_ROOT/cross-tools"
# 	SRC_DIR="$STELLA_APP_FEATURE_ROOT/binutils-$VER-src"
# 	BUILD_DIR="$STELLA_APP_FEATURE_ROOT/binutils-$VER-build"

# 	AUTO_INSTALL_FLAG_PREFIX="AR=ar AS=as"
# 	AUTO_INSTALL_FLAG_POSTFIX="--host=$CROSS_HOST --target=$CROSS_TARGET \
#   	--with-sysroot=${CLFS} --with-lib-path=/tools/lib --disable-nls \
#   	--disable-static --enable-64-bit-bfd"

# 	__auto_build "configure" "binutils" "$FILE_NAME" "$URL" "$SRC_DIR" "$BUILD_DIR" "$INSTALL_DIR" "STRIP"
# }









fi
