#!/bin/bash -l

# find this script and establish base directory
curr_dir=`dirname $0`
MY_DIR=`cd $curr_dir; pwd`
echo "[INFO] Executing in ${MY_DIR}"

PACKAGE_NAME=${PACKAGE_NAME:-"scala-pickling"}
PACKAGE_BRANCH=${PACKAGE_BRANCH:-"0.11.x"}
BUILD_BRANCH=${BUILD_BRANCH:-"v0.11.x-M1_2.11"}
ALTISCALE_RELEASE="${ALTISCALE_RELEASE:-5.0.0}"

rm -rf install-dir-*
rm -rf rpm-dir-*

echo "ok - $(whoami) user is going to build the project"
echo "ok - fpm is located at $(which fpm)"
echo "ok - PATH=$PATH"
echo "ok - BUILD_BRANCH=$BUILD_BRANCH"
echo "ok - PACKAGE_BRANCH=$PACKAGE_BRANCH"

ret=0
export DATE_STRING=${DATE_STRING:-$(date -u +%Y%m%d%H%M)}
RPM_INSTALL_DIR=${MY_DIR}/picklingrpmbuild
echo "RPM_INSTALL_DIR : $RPM_INSTALL_DIR"
pushd ${MY_DIR}

export RPM_NAME=`echo scala-pickling-${BUILD_BRANCH}`
export RPM_DESCRIPTION="scala-pickling library ${BUILD_BRANCH}"
echo "RPM_NAME : $RPM_NAME"
echo "RPM_DESCRIPTION : $RPM_DESCRIPTION"
echo "Current directory : ${pwd}"

##################
# Packaging  RPM #
##################
echo "Packaging RPM"
export RPM_BUILD_DIR="${RPM_INSTALL_DIR}/usr/sap/spark/controller/"
# Generate RPM based on where spark artifacts are placed from previous steps
rm -rf "${RPM_BUILD_DIR}"
mkdir --mode=0755 -p "${RPM_BUILD_DIR}"

if [[ "$BUILD_BRANCH" == *_2.10 ]] ; then
  mkdir --mode=0755 -p "${RPM_BUILD_DIR}/lib"
  cp -rp /imports/scala-pickling_2.10-*.jar $RPM_BUILD_DIR/lib/
elif [[ "$BUILD_BRANCH" == *_2.11 ]] ; then
  mkdir --mode=0755 -p "${RPM_BUILD_DIR}/lib_2.11"
  cp -rp /imports/scala-pickling_2.11-*.jar $RPM_BUILD_DIR/lib_2.11/
else
  echo "fatal - unsupported version for $BUILD_BRANCH, can't produce RPM, quitting!"
  exit -1
fi

mkdir -p "${RPM_BUILD_DIR}/licenses"
cp LICENSE "${RPM_BUILD_DIR}/licenses/LICENSE-${RPM_NAME}"
echo "cp successful"

echo "running mkdir for RPM_INSTALL_DIR"
mkdir -p ${RPM_INSTALL_DIR}
pushd ${RPM_INSTALL_DIR}

echo "Executing fpm command"
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
-v ${ALTISCALE_RELEASE} \
--iteration ${DATE_STRING} \
--rpm-user root \
--rpm-group root \
--rpm-auto-add-directories \
-C ${RPM_INSTALL_DIR} \
usr

if [ $? -ne 0 ] ; then
	echo "FATAL: scala-pickling rpm build fail!"
	popd
	exit -1
fi

mv "${RPM_INSTALL_DIR}/${RPM_NAME}-${ALTISCALE_RELEASE}-${DATE_STRING}.noarch.rpm" "${RPM_INSTALL_DIR}/alti-pickling-${PACKAGE_BRANCH}.rpm"
popd

ls -al $RPM_INSTALL_DIR
pwd
find . -name *.rpm -print

echo "ok - build Pickling $PACKAGE_BRANCH and RPM completed successfully!"

exit 0
