#! /bin/bash

FILE_PATH=$1
# On ajoute le fichier et on récupère le hash
HASH=$(/usr/local/bin/ipfs-cluster-ctl --quiet add ${FILE_PATH})
