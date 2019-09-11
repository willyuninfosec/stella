# shellcheck shell=bash
if [ ! "$_openjdk_INCLUDED_" = "1" ]; then
_openjdk_INCLUDED_=1


# Recipe for Open Java Development Kit (=JDK)

# CHANGE in Java/Oracle Licence model:
#		* It is impossible to automate oraclejdk download now
#		* Now there is OpenJDK and OracleJDK
#		* There is a lot of OpenJDK distributor including Oracle (so OpenJDK crom Oracle is not the same than OracleJDK)

# List of OpenJDK distributor : https://dzone.com/articles/java-and-the-jdks-which-one-to-use

# sample usage :
# openjdk=adoptopenjdk ./stella.sh feature install openjdk


feature_openjdk() {
	FEAT_NAME="openjdk"
	FEAT_BUNDLE="PROXY"

	FEAT_BUNDLE_PROXY_DEFAULT="adoptopenjdk"
	FEAT_BUNDLE_PROXY_LIST="adoptopenjdk amazoncorretto"
	


}

fi
