pushd molecule
# remove the openstack scenario files
rm -rf openstack
# remove dependency on oasis_roles.molecule_openstack_ci
sed -i '2d' shared/requirements.yml
# change any usages of openstack to docker
grep -lRZ 'openstack' . | xargs -0 -l sed -i -e 's/openstack/docker/g'
