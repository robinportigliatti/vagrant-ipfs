# Installer ansible

Suivre le tuto d'installation [ici](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip).

# Installer vagrant

Suivre le tuto d'installation [ici](https://www.vagrantup.com/docs/installation).

# Configurer vagrant

Si vous utiliser `libvirt` pour la virtualisation il faudra installer le plugin `libvirt` à partir de vagrant.

```
vagrant plugin install libvirt
```

# Création des VMs

Pour lancer la création et la provision de toutes les VMs :
```
vagrant up --provision [--provider libvirt]
```

Pour lancer la création et la provision d'une VM :
```
vagrant up [ipfs_1 | ipfs_2] --provision  [--provider libvirt]
```

# Accès au VM

```
vagrant ssh [ipfs_1 | ipfs_2]
```

| Nom               | Adresse Ip    |
| ----------------- | ------------- |
| ipfs_1            | 192.168.60.11 |
| ipfs_2            | 192.168.60.12 |

# Suppression des VMs

Pour lancer la suppression de toutes les VMs :
```
vagrant destroy --force
```

Pour lancer la suppression et d'une VM :
```
vagrant destroy [ipfs_1 | ipfs_2 ] --force
```

# Utilisation de IPFS

Sur la node ipfs_1 en tant que postgres:
```
-bash-4.2$ echo "Je suis sur ipfs_1" > 1.txt
-bash-4.2$ ipfs add 1.txt
added QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU 1.txt
 17 B / 17 B [==================================================================================] 100.00%
```

Récupérer le hash `QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU`

Sur la node ipfs_2 en tant que postgres:

Pour afficher le contenu et voir que tout a bien marché:
```
ipfs cat QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU
```

Pour ajouter le fichier à la node ipfs_2:
```
ipfs pin add QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU
```

# Archivage

## Initialisation

### Noeud secondaire

C'est sur le noeud secondaire que nous allons nous abonner à l'abonnement, ici `demo`:
```
ipfs pubsub sub demo
```

### Noeud primaire

Nous mettons en `archive_command` la commande ci-dessous:

```
ipfs-cluster-ctl add --quiet %p | awk '{ print $1 " " "%f" }' | ipfs pubsub pub demo
```

On reload le service postgres

```
service postgresql-14 reload
```

Puis sur la console psql on lance un switch des wals:

```
SELECT pg_switch_wal();
```

Sur le noeud secondaire il sera possible de voir le nouveau hash du fichier dans la console:

```
[ipfs@ipfs2 ~]$ ipfs pubsub sub demo
QmWpQt68B6iv7fuNrr3aRNHB2JUGXrRbBvvo4SGLkoDcDx
```

## Lecture d'un WAL

A partir du second noeud nous récupérons le fichier avec le hash récupéré
à l'étape précédente:

```
ipfs get QmWpQt68B6iv7fuNrr3aRNHB2JUGXrRbBvvo4SGLkoDcDx
```

# log_shipping

## Noeud primaire

Sur le noeud primaire l'archive_command ajoute les fichiers à IPFS et prévient les abonnés du changements:

```
archive_command = 'ipfs-cluster-ctl add --quiet %p | awk \'{ print $1 " " "%f" }\' | ipfs pubsub pub demo'
```

## Noeud secondaire

Le service `ipfs-pubsub-listen-demo` écoute le topic `demo` et ajout dans les WAL dans `/tmp/demo/pg_wal`:
```
#!/bin/bash

mkdir -p /tmp/demo/pg_wal
ipfs pubsub sub demo | while read -r line
do
    read -a arr <<< $line

    echo "/tmp/demo/pg_wal/${arr[1]}"
    ipfs get ${arr[0]} --output="/tmp/demo/pg_wal/${arr[1]}"
    echo "File ${arr[1]} ready to be processed"
done
```

Postgres avec le restore_command copie les fichier dans `$PGDATA/pg_wal` et les supprime avec archive_cleanup_command:

```
restore_command = 'cp /tmp/demo/pg_wal/%f %p'
archive_cleanup_command = 'pg_archivecleanup /tmp/demo/pg_wal %r'
```

# Intérêt

Lors de l'ajout d'un WAL au réseau IPFS, ce WAL est propagé sur tous les noeuds faisant partie du réseau de notre cluster IPFS.

Si une suppression a lieu sur le système de fichier du primaire, et que sur le primaire on décide de ne plus fournir (`unpin`) le fichier sur le noeud IPFS local, le fichier sera toujours accessible sur le réseau IPFS par les autres noeuds.

Lorsqu'un secondaire voudra récupérer un fichier, il téléchargera le fichier sur tous les noeuds faisant partie du cluster. Améliorant le téléchargement du fichier (en théorie)

# Questions

## Que se passe-t-il si un nouveau est ajouté ? les fichiers sont récupérés ?

Je pense qu'il ne sont pas `pin` (récupéré) mais seront forcément accessibles.

A voir donc l'aspect `pin`.

## DUMP dans IPFS ?

```
pg_dump -Fc | ipfs add
```

`-Fd ` ne marchera pas car il a besoin du filesystem.

## pg_base_backup dans IPFS ?

Il faudra lancer le pg_basebackup

```
pg_basebackup --pgdata=/tmp/demo/backup_tmp --format=t --gzip
```

Puis `pin` le dossier à IPFS:

```
$ ipfs-cluster-ctl add --quieter -r /tmp/demo/backup_tmp
QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx
```

Puis depuis un postgres récupérer le répertoire:

```
$ ipfs get QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx
Saving file(s) to QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx
 3.34 MiB / 3.34 MiB [=======================================================================] 100.00% 0s
$ ll QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx/*
total 3420
-rw-------. 1 postgres postgres  137935 Jan 14 15:48 backup_manifest
-rw-------. 1 postgres postgres 3341746 Jan 14 15:48 base.tar.gz
-rw-------. 1 postgres postgres   17070 Jan 14 15:48 pg_wal.tar.gz
```

## Comment se passe la purge des fichiers ?

Lors de l'ajout d'un fichier au cluster IPFS, il faudra préciser `--expire-in`
dont la valeur est en `s|m|h`:
```
ipfs-cluster-ctl add --quieter --expire-in 12h -r /tmp/demo/backup_tmp
```

Le backup sera disponible `pin` sur le cluster pendant 12 heures. Après il ne
ce laps de temps il ne le sera plus et il faudra lancer le garbage collector sur
tous les noeuds avec :

```
ipfs-cluster-ctl ipfs gc
```
