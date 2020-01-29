ROLE_PATH=$1
LIBRARY_PATH=$2
for f in $(find ${LIBRARY_PATH} -maxdepth 1 -type f); do
    module=$(awk '/module:/{ print $2 }' $f)
    if grep -rn "$module" ${ROLE_PATH}/tasks/ &> /dev/null; then
        pushd library
	ln -s ../$f .
	popd
        echo $f
    fi
done
