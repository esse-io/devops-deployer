set -x

# ignore error if the schema was already created
./ooziedb.sh create -run
exit 0
