@echo off
call %*
goto :eof

:list_packer
	set "%~1=0_6_0_x64 0_6_0_x86"
goto :eof

:default_packer
	set "%~1=0_6_0_x64"
goto :eof


:install_packer
	set "_VER=%~1"
	call :default_packer "_DEFAULT_VER"

	if not exist %STELLA_APP_FEATURE_ROOT%\packer mkdir %STELLA_APP_FEATURE_ROOT%\packer
	if "%_VER%"=="" (
		call :install_packer_!_DEFAULT_VER!
	) else (
		call :install_packer_%_VER%
	)
goto :eof

:feature_packer
	set "_VER=%~1"
	call :default_packer "_DEFAULT_VER"

	if "%_VER%"=="" (
		call :feature_packer_!_DEFAULT_VER!
	) else (
		call :feature_packer_%_VER%
	)
goto :eof

REM --------------------------------------------------------------
:install_packer_0_6_0_x64
	set URL=https://dl.bintray.com/mitchellh/packer/0.6.0_windows_amd64.zip
	set FILE_NAME=0.6.0_windows_amd64.zip
	set VERSION=0_6_0_x64
	call :install_packer_internal
goto :eof

:install_packer_0_6_0_x86
	set URL=https://dl.bintray.com/mitchellh/packer/0.6.0_windows_386.zip
	set FILE_NAME=0.6.0_windows_386.zip
	set VERSION=0_6_0_x86
	call :install_packer_internal
goto :eof

:feature_packer_0_6_0_x64
	set "FEATURE_TEST=%STELLA_APP_FEATURE_ROOT%\packer\0_6_0_x64\packer.exe"
	set "FEATURE_RESULT_PATH=%STELLA_APP_FEATURE_ROOT%\packer\0_6_0_x64"
	set "FEATURE_RESULT_VER=0_6_0_x64"
	call :feature_packer_internal
goto :eof

:feature_packer_0_6_0_x86
	set "FEATURE_TEST=%STELLA_APP_FEATURE_ROOT%\packer\0_6_0_x86\packer.exe"
	set "FEATURE_RESULT_PATH=%STELLA_APP_FEATURE_ROOT%\packer\0_6_0_x86"
	set "FEATURE_RESULT_VER=0_6_0_x86"
	call :feature_packer_internal
goto :eof



REM --------------------------------------------------------------
:install_packer_internal
	set "INSTALL_DIR=%STELLA_APP_FEATURE_ROOT%\packer\%VERSION%"

	echo ** Installing packer version %VERSION% in %INSTALL_DIR%
	call :feature_packer_%VERSION%
	if "%FORCE%"=="1" ( 
		set TEST_FEATURE=0
		call %STELLA_COMMON%\common.bat :del_folder "%INSTALL_DIR%"
	)
	if "!TEST_FEATURE!"=="0" (
		call %STELLA_COMMON%\common.bat :download_uncompress "%URL%" "%FILE_NAME%" "%INSTALL_DIR%" "DEST_ERASE"
		
		call :feature_packer_%VERSION%
		if not "!TEST_FEATURE!"=="0" (
			cd /D "!TEST_FEATURE!"
			echo Packer installed
			packer --version
		) else (
			echo ** ERROR
		)
	) else (
		echo ** Already installed
	)
goto :eof

:feature_packer_internal
	set TEST_FEATURE=0
	set FEATURE_PATH=
	set FEATURE_VER=
	if exist "!FEATURE_TEST!" (
		set "TEST_FEATURE=!FEATURE_RESULT_PATH!"
	)

	if not "!TEST_FEATURE!"=="0" (
		if %VERBOSE_MODE% GTR 0 (
			echo ** EXTRA FEATURE Detected : packer in !TEST_FEATURE!
		)
		REM set "PACKER_CMD=!TEST_FEATURE!\%PACKER_CMD%"
		set "FEATURE_PATH=!TEST_FEATURE!"
		set FEATURE_VER=!FEATURE_RESULT_VER!
	)
goto :eof

