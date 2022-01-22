FILE_PATH=$1
/usr/local/bin/ipfs-cluster-ctl add ${FILE_PATH} >> /tmp/ipfs-postgres.manifest
MANIFEST_HASH=$(/usr/local/bin/ipfs-cluster-ctl add --quiet /tmp/ipfs-postgres.manifest)
/usr/local/bin/ipfs name publish ${MANIFEST_HASH}
