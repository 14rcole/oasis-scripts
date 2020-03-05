#!/usr/bin/bash -xe

# declare variable
LP_PATH=$1
ROLE_NAME=$2
ROLE_PATH=$(pwd)/${ROLE_NAME}
SCRIPTS_DIR=$(pwd)

update_metadata() {
    echo "galaxy_info:
  author: Samvaran Rallabandi
  description: ${ROLE_NAME} provisioning for LinchPin
  company: Red Hat, Inc.
  license: GPLv3
  min_ansible_version: 2.8
  platforms:
    - name: EL
      versions:
        - 7
        - 8
    - name: Fedora
      versions:
        - 30
        - 31
  
  galaxy_tags:
    - oasis
    - linchpin
    - ${ROLE_NAME}
" > ${ROLE_NAME}/meta/main.yml
}

replace_links() {
    SRC_PATH=$1
    DEST_PATH=$2
    rm ${DEST_PATH} # remove link so that it can be replaced with a directory
    mkdir ${DEST_PATH}
    for f in $(find ${SRC_PATH}/ -maxdepth 1 -name "*.py" -type f); do
	if [[ "$DEST_PATH" == "library" ]]; then
            item=$(awk '/module:/{ print $2 }' $f)
	else # in this case, DEST_PATH is filter_plugins
            item=$(awk -v FPAT="([^ :']+)" '/filter_utils./{ print $1 }' $f)
	fi
        if [ -n "$item" ] && grep -rn "$item" ${ROLE_PATH}/tasks/ &> /dev/null; then
            pushd ${DEST_PATH}
    	    ln -s ../$f .
    	    popd
        fi
    done
}

library() {
    LIBRARY_PATH=$1
    rm library
    mkdir library
    for f in $(find ${LIBRARY_PATH} -maxdepth 1 -name "*.py" -type f); do
        module=$(awk '/module:/{ print $2 }' $f)
        if grep -rn "$module" ${ROLE_PATH}/tasks/ &> /dev/null; then
            pushd library
    	ln -s ../$f .
    	popd
        fi
    done
}

remove_openstack() {
    pushd ${ROLE_NAME}/molecule
    # remove the docker scenario files
    rm -rf openstack
    # remove dependency on oasis_roles.molecule_docker_ci
    sed -i '2d' shared/requirements.yml
    # change any usages of docker to docker
    ls ./docker/molecule.yml
    grep -lRZ 'openstack' . | xargs -0 -l -r sed -i -e 's/openstack/docker/g'
    popd
}

if [ ! -d "meta_skeleton" ] ; then
    git clone https://github.com/oasis-roles/meta_skeleton
else
    pushd meta_skeleton
    git pull origin master
    popd
fi

echo "> initializing new role with meta_skeleton..."
ansible-galaxy init --role-skeleton=meta_skeleton ${ROLE_NAME}

echo "> copying existing role..."
cp -R ${LP_PATH}/linchpin/provision/roles/${ROLE_NAME}/* ${ROLE_PATH}

# update all references to "include:" to "include_tasks:"
# NOTE: include_tasks is static, import_tasks is dynamic
# If a reference to "include:" included "static: yes" then it should have beome
# "import_tasks" and this will need to be done by hand
echo "> replacing deprecated 'include' task..."
find $ROLE_NAME -name "*.yml" -exec sh replace_includes.sh {} \;

echo "> removing unecessary files..."
rm ${ROLE_NAME}/LICENSE
rm ${ROLE_NAME}/Jenkinsfile
rm ${ROLE_NAME}/README.md
rm ${ROLE_NAME}/.travis.yml # we do all of this testing already, just differently

echo "> Fix ansible linting..."
echo "  - \"503\"  # disable \"Tasks run when changed should be handlers\"" >> ${ROLE_NAME}/.ansible-lint

# CHANGME to your own name and email address
echo "Ryan Cole <rycole@redhat.com>" > ${ROLE_NAME}/AUTHORS

echo "> updating metadata file..."
update_metadata

echo "> removing the openstack provider in molecule..."
remove_openstack

echo "> copying the new role back to linchpin"
rm -rf ${LP_PATH}/linchpin/provision/roles/${ROLE_NAME}
ls ${LP_PATH}/linchpin/provision/roles
cp -R ${ROLE_PATH} ${LP_PATH}/linchpin/provision/roles/

# cd to new role directory
pushd ${LP_PATH}/linchpin/provision/roles/${ROLE_NAME}

# link each filter plugin individually
# we can just continue linking the whole directory, but it makes it easier to
# separate these into roles if we know exactly which filters are used for each
# provider
echo "> updating filter plugins..."
replace_links ../../filter_plugins filter_plugins

# Same as above, but with libraries instead of filter plugins
echo "> updating libraries..."
replace_links ../../library library

popd

echo "> cleaning up..."
rm -rf ${ROLE_NAME}
echo "> finished"
