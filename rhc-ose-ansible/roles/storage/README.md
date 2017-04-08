# storage Ansible Role

Configures Disk partitions, VGs, LVs, filesystem, and mount points

## To Test

Create play as follows:

[source,yaml]
```
---
- hosts: storage_hosts
  roles:
    - storage
```

Add following to hosts file:

[source,ini]
```
[storage_hosts]
hostname
```

Create a host groups var at {inventory_dir}/group_vars/storage_hosts like:

[source,yaml]
```
volume_groups:
- disk: /dev/vdb
  vg: vg_sat6
  fstype: xfs
logical_volumes:
- vg: vg_sat6
  lv: lv_pulp
  mount_point: /var/lib/pulp
  lv_size: 40960
  fstype: xfs
- vg: vg_sat6
  lv: lv_mongodb
  mount_point: /var/lib/mongodb
  lv_size: 12288
  fstype: xfs
- vg: vg_sat6
  lv: lv_pgsql
  mount_point: /var/lib/pgsql
  lv_size: 2048
  fstype: xfs
- vg: vg_sat6
  lv: lv_varwww
  mount_point: /var/www/html
  lv_size: 2048
  fstype: xfs
```
Run playbook:

```
ansible-playbook -i {inventory_dir}/hosts plays/storage_play.yml
```
