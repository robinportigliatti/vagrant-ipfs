# Install ansible

Follow this [link](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-and-upgrading-ansible-with-pip).

# Install vagrant

Follow this [link](https://www.vagrantup.com/docs/installation).

# Creating VM

Create and provision the VMs :

```
make all
```

Only provision :

```
make provision
```

# Access to the VMs

```
vagrant ssh [ipfs_1 | ipfs_2]
```

| Name               | Ip    |
| ----------------- | ------------- |
| ipfs_1            | 192.168.60.11 |
| ipfs_2            | 192.168.60.12 |

# Destroy VMs

```
make destroy
```

# Usage of IPFS

On node ipfs_1 as **postgres** :
```
-bash-4.2$ echo "I am on ipfs_1" > 1.txt
-bash-4.2$ ipfs add 1.txt
added QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU 1.txt
 17 B / 17 B [==================================================================================] 100.00%
```

Get the hash `QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU`

On the node ipfs_2 as **postgres**:

To display the content :

```
/usr/local/bin/ipfs cat QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU
```

To pin the file on ipfs_2:
```
/usr/local/bin/ipfs pin add QmRzQT5ka4AzUs97Wh1wjoB8svHnRVb74M1aUPDr4Ny6eU
```

# Archiving

## Init

### Secondary node

It is on the secondary node (ipfs_2) that we subscribe to the publication, here `demo`:

```
/usr/local/bin/ipfs pubsub sub demo
```

### Primary node

We update the `archive_command` parameter with the following command :

```
/usr/local/bin/ipfs-cluster-ctl add --quiet %p | awk '{ print $1 " " "%f" }' | ipfs pubsub pub demo
```

We reload the postgresql server:

```
sudo service postgresql-14 reload
```

Then with psql we switch the WAL:

```
psql -c "SELECT pg_switch_wal();"
```

On the secondary node, it will be possible de see the new hash from the console:

```
[ipfs@ipfs2 ~]$ /usr/local/bin/ipfs pubsub sub demo
QmWpQt68B6iv7fuNrr3aRNHB2JUGXrRbBvvo4SGLkoDcDx
```

## Reading a WAL file

From the secondary node we get the file with the hash we got from earlier

```
/usr/local/bin/ipfs get QmWpQt68B6iv7fuNrr3aRNHB2JUGXrRbBvvo4SGLkoDcDx
```

# Log shipping

## Primary node

On the primary node `archive_command` paaremeter is set to execute a command that will add files to the IPFS
cluster and will warn the subscriber for any change:

```
archive_command = '/usr/local/bin/ipfs-cluster-ctl add --quiet %p | awk \'{ print $1 " " "%f" }\' | ipfs pubsub pub demo'
```

## Secondary node

On the secondary node, the service `ipfs-pubsub-listen-demo` listens to the `demo` topic and get the WAL to `/tmp/demo/pg_wal`:

```
#!/bin/bash

mkdir -p /tmp/demo/pg_wal
/usr/local/bin/ipfs pubsub sub demo | while read -r line
do
    read -a arr <<< $line

    echo "/tmp/demo/pg_wal/${arr[1]}"
    /usr/local/bin/ipfs get ${arr[0]} --output="/tmp/demo/pg_wal/${arr[1]}"
    echo "File ${arr[1]} ready to be processed"
done
```

Then PostgreSQl with the command inside `restore_commande` paremeter copy the file inside `$PGDATA/pg_wal` and delete them with
the command inside `archive_cleanup_command` parameter:

```
restore_command = 'cp /tmp/demo/pg_wal/%f %p'
archive_cleanup_command = 'pg_archivecleanup /tmp/demo/pg_wal %r'
```

# Advantages

When adding a WAL to the IPFS network this WAL is 

When adding a WAL to the IPFS network, this WAL is propagated to all nodes that are part of our IPFS cluster network.

If the WAL is deleted on the primary, it will stay on all other IPFS nodes. Even if it is unpinned.

When a secondary node will need to get the file, it will download it from all others nodes and not from only one node.

# Questions

## What happens when an IPFS node is added to the network . Does the files will be automatically pinned ?

No they, only those marked pinned will be stored on the IPFS node. All other files will accessible.

## pg_dump inside IPFS ?

```
pg_dump -Fc | ipfs add
```

`-Fd ` won't work since it need access to the filesystem.

## pg_base_backup inside IPFS ?

```
pg_basebackup --pgdata=/tmp/demo/backup_tmp --format=t --gzip
```

Then `pin` the directory:

```
$ /usr/local/bin/ipfs-cluster-ctl add --quieter -r /tmp/demo/backup_tmp
QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx
```

Then from a postgresql node get the directory with the hash:

```
$ /usr/local/bin/ipfs get QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx
Saving file(s) to QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx
 3.34 MiB / 3.34 MiB [=======================================================================] 100.00% 0s
$ ll QmW6m3H9FQJbYwMZKKvWEUdoUWkfx9Y4HaZftvFJ8ty4kx/*
total 3420
-rw-------. 1 postgres postgres  137935 Jan 14 15:48 backup_manifest
-rw-------. 1 postgres postgres 3341746 Jan 14 15:48 base.tar.gz
-rw-------. 1 postgres postgres   17070 Jan 14 15:48 pg_wal.tar.gz
```

## When does the files are deleted from the cluster ?

When adding a file to the IPFS cluster, you will need to specify `--expire-in` argument!

```
/usr/local/bin/ipfs-cluster-ctl add --quieter --expire-in 12h -r /tmp/demo/backup_tmp
```

Then all the files pinned to cluster will be available for 12 hours.
And the garbage collector needs to be launched:

```
/usr/local/bin/ipfs-cluster-ctl ipfs gc
```
