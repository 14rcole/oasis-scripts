#!/usr/bin/bash

# declare variable
LP_PATH=$1
ROLE_NAME=$2
ROLE_PATH=$(pwd)/${ROLE_NAME}
SCRIPTS_DIR=$(pwd)

if [ ! -d "meta_skeleton" ] ; then
    git clone https://github.com/oasis-roles/meta_skeleton
else
    pushd meta_skeleton
    git pull https://github.com/oasis-roles/meta_skeleton
    popd
fi

# initalize OASIS role skeleton
ansible-galaxy init --role-skeleton=meta_skeleton ${ROLE_NAME}

# copy role to skeleton directory
cp -R ${LP_PATH}/linchpin/provision/roles/${ROLE_NAME} ${ROLE_PATH}

# update all references to "include:" to "include_tasks:"
# NOTE: include_tasks is static, import_tasks is dynamic
# If a reference to "include:" included "static: yes" then it should have beome
# "import_tasks" and this will need to be done by hand
find -name "*.yml" | xargs sh replace.sh

# copy the "new" role back to linchpin
rm -rf ${LP_PATH}/linchpin/provision/roles/${ROLE_NAME}
cp -R ${ROLE_PATH} ${LP_PATH}/linchpin/provision/roles/

# delete the openstack provider
rm -rf ${ROLE_PATH}/molecule/openstack

# cd to new role directory
pushd ${LP_PATH}/linchpin/provision/roles/${ROLE_NAME}

# link each filter plugin individually
# we can just continue linking the whole directory, but it makes it easier to
# separate these into roles if we know exactly which filters are used for each
# provider
rm filter_plugins # remove the link
mkdir filter_plugins
sh ${SCRIPTS_DIR}/filter.sh  $(pwd) ../../filter_plugins

# Same as above, but with libraries instead of filter plugins
rm library
mkdir library
sh ${SCRIPTS_DIR}/library.sh ${ROLE_PATH} ../../library
