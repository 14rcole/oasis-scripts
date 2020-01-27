ROLE_PATH=$1
FILTERS_PATH=$2
for f in $(find ${FILTERS_PATH}/ -maxdepth 1 -type f); do
    filter=$(awk -v FPAT="([^ :']+)" '/filter_utils./{ print $1 }' $f)
    if grep -rn "$filter" ${ROLE_PATH}/tasks/ &> /dev/null; then
        pushd filter_plugins
	ln -s ../${FILTERS_PATH}/$f .
	popd
	echo $f
    fi
done
