# OASIS Scripts

To run the scripts, simply run `sh make-compatible.sh` /path/to/linchpin/ $ROLE_NAME

`make-compatible.sh` will then take the following steps:
1. clone the meta skeleton
2. initialize a galaxy role
3. copy the role into the galaxy role
4. replace any `include:` tasks (now deprecated) with `import_tasks`
5. move the new role back to linchpin
6. update the filter plugins to only include those that are necessary for LinchPin
7. update the libraries to only include those that are necessary for linchpin
