#!/bin/bash -l
echo "Inside file -- sap-xmake-build.sh --"

cd ${WORKSPACE}

# NEW CHANGES
PACKAGE_NAME=${PACKAGE_NAME:-"scala-pickling"}
PACKAGE_BRANCH=${PACKAGE_BRANCH:-"0.11.x"}
BUILD_BRANCH=${BUILD_BRANCH:-"v0.11.0-M1_2.11"}
echo "PACKAGE_NAME : $PACKAGE_NAME"
echo "PACKAGE_BRANCH : $PACKAGE_BRANCH"
echo "BUILD_BRANCH : $BUILD_BRANCH"

mkdir -p hack_target
pushd hack_target
rm -rf *.jar
# wget -O scala-pickling_2.11-0.11.0-M1.jar "http://central.maven.org/maven2/org/scala-lang/modules/scala-pickling_2.11/0.11.0-M1/scala-pickling_2.11-0.11.0-M1.jar"
# wget -O scala-pickling_2.10-0.11.0-M1.jar "http://central.maven.org/maven2/org/scala-lang/modules/scala-pickling_2.10/0.11.0-M1/scala-pickling_2.10-0.11.0-M1.jar"
# wget -O scala-pickling_2.11-0.10.1.jar "https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=org.scala-lang.modules&a=scala-pickling_2.11&v=0.10.0&e=jar"
# wget -O scala-pickling_2.10-0.10.1.jar "https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=org.scala-lang.modules&a=scala-pickling_2.10&v=0.10.0&e=jar"
popd
rm -rf install-dir-*
rm -rf rpm-dir-*
# END

echo "ok - $(whoami) user is going to build the project"
echo "ok - fpm is located at $(which fpm)"
echo "ok - PATH=$PATH"
echo "ok - BUILD_BRANCH=$BUILD_BRANCH"
echo "ok - PACKAGE_BRANCH=$PACKAGE_BRANCH"

echo " STEP 1"

ret=0
export DATE_STRING=${DATE_STRING:-$(date -u +%Y%m%d%H%M)}
INSTALL_DIR=${WORKSPACE}/install-dir-${DATE_STRING}
RPM_DIR=${WORKSPACE}/rpm-dir-${DATE_STRING}
echo "INSTALL_DIR : $INSTALL_DIR"
echo "RPM_DIR : $RPM_DIR"
pushd ${WORKSPACE}

# pushd ${WORKSPACE}/pickling
# sbt package
# ret=$?

# This is a hack to just package the JAR before we can build it correctly
# hack_target should exist already with the JARs we need
export RPM_NAME=`echo scala-pickling-${BUILD_BRANCH}`
export RPM_DESCRIPTION="scala-pickling library ${BUILD_BRANCH}"
echo "RPM_NAME : $RPM_NAME"
echo "RPM_DESCRIPTION : $RPM_DESCRIPTION"
echo "Current directory : ${pwd}"

##################
# Packaging  RPM #
##################
echo "Packaging RPM"
export RPM_BUILD_DIR="${INSTALL_DIR}/usr/sap/spark/controller/"
# Generate RPM based on where spark artifacts are placed from previous steps
rm -rf "${RPM_BUILD_DIR}"
mkdir --mode=0755 -p "${RPM_BUILD_DIR}"

echo "STEP 2"
pushd hack_target
if [[ "$BUILD_BRANCH" == *_2.10 ]] ; then
  mkdir --mode=0755 -p "${RPM_BUILD_DIR}/lib"
  cp -rp /import/scala-pickling_2.10-*.jar $RPM_BUILD_DIR/lib/
elif [[ "$BUILD_BRANCH" == *_2.11 ]] ; then
  mkdir --mode=0755 -p "${RPM_BUILD_DIR}/lib_2.11"
  cp -rp /import/scala-pickling_2.11-*.jar $RPM_BUILD_DIR/lib_2.11/
else
  echo "fatal - unsupported version for $BUILD_BRANCH, can't produce RPM, quitting!"
  exit -1
fi
popd

echo "STEP 3"
mkdir -p "${RPM_BUILD_DIR}/licenses"
cp LICENSE "${RPM_BUILD_DIR}/licenses/LICENSE-${RPM_NAME}"
echo "cp successful"

echo "running mkdir for RPM_DIR"
mkdir -p ${RPM_DIR}
pushd ${RPM_DIR}

echo "
fpm --verbose \
--maintainer andrew.lee02@sap.com \
--vendor SAP \
--provides ${RPM_NAME} \
--description "$(printf "${RPM_DESCRIPTION}")" \
--replaces ${RPM_NAME} \
--url "https://github.com/Altiscale/pickling" \
--license "Proprietary" \
--epoch 1 \
--rpm-os linux \
--architecture all \
--category "Development/Libraries" \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${BUILD_BRANCH} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
--rpm-auto-add-directories \
-C ${INSTALL_DIR} \
"

echo "fpm command"
fpm --verbose \
--maintainer andrew.lee02@sap.com \
--vendor SAP \
--provides ${RPM_NAME} \
--description "$(printf "${RPM_DESCRIPTION}")" \
--replaces ${RPM_NAME} \
--url "https://github.com/Altiscale/pickling" \
--license "Proprietary" \
--epoch 1 \
--rpm-os linux \
--architecture all \
--category "Development/Libraries" \
-s dir \
-t rpm \
-n ${RPM_NAME} \
-v ${BUILD_BRANCH} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
--rpm-auto-add-directories \
-C ${INSTALL_DIR} \
usr

if [ $? -ne 0 ] ; then
	echo "FATAL: scala-pickling rpm build fail!"
	popd
	exit -1
fi
popd

find . -name *.rpm -print
echo "reached here!!"
exit 0
