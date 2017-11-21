#!/usr/bin/env python


def main():

    from subprocess import check_output
    import shlex
    import os
    import re

    # osd
    mount_path = check_output("df -h | awk '{print $6}' | grep ceph | grep -v lockbox | sed 's/[0-9]*//g' | awk 'NR==1{print $1}'", shell=True).rstrip()
    sed = 'sed \'s#{0}##g\''.format(mount_path)
    cmd = "lsblk -rp | awk '{print $1,$6,$7}' | grep -v lockbox | grep ceph | " + sed
    osd_output = check_output(cmd, shell=True)
    grain = {}
    grain["ceph"] = {}
    if osd_output:
        devices = {}
        for line in osd_output.splitlines():
            device = line.split()
            encrypted = False
            if "crypt" in device[1]:
                output = check_output("lsblk -rp | grep -B1 " + device[0], shell=True)
                for l in output.splitlines():
                    d = l.split()
                    dev = d[0].replace('1','')
                    encrypted = True
                    break
            else:
                dev = device[0].replace('1','')
            device[0] = device[2]
            devices[device[0]] = {}
            devices[device[0]]['dev'] = dev
            if encrypted:
                devices[device[0]]['dmcrypt'] = 'true'
            tline = check_output("ceph osd tree | awk '{print $1,$2,$3,$4}' | grep -w 'osd." + device[0] + "'", shell=True)
            osd = tline.split()
            if "osd" not in osd[2]:
                crush_class = osd[1]
                crush_weight = osd[2]
                devices[device[0]]['class'] = crush_class
                devices[device[0]]['weight'] = crush_weight
            else:
                crush_weight = osd[1]
                devices[device[0]]['weight'] = crush_weight
        grain["ceph"]["ceph_disk"] = devices

    # keyrings
    directory = '/etc/ceph/'
    keyrings = {}
    if os.path.isdir(directory):
        for filename in os.listdir(directory):
            if filename.endswith(".keyring") and filename.startswith("ceph.client"):
                keyring_output = open(os.path.join(directory, filename), "r")
                keyring_name = re.search('ceph.client.(.+?).keyring', filename).group(1)
                if keyring_output:
                    keyrings[keyring_name] = {}
                    for line in keyring_output:
                        attr = shlex.split(line)
                        if attr:
                            if attr[0] == 'key':
                                keyrings[keyring_name]['key'] = attr[2]
                            if attr[0] == 'caps' and 'caps' in keyrings[keyring_name]:
                                keyrings[keyring_name]['caps'][attr[1]] = attr[3]
                            elif attr[0] == 'caps' and 'caps' not in keyrings[keyring_name]:
                                keyrings[keyring_name]['caps'] = {}
                                keyrings[keyring_name]['caps'][attr[1]] = attr[3]
        if keyrings:
            grain["ceph"]["ceph_keyring"] = keyrings

    # mon keyring
    hostname = check_output("hostname", shell=True).rstrip()
    filepath = "/var/lib/ceph/mon/ceph-{0}/keyring".format(hostname)
    if os.path.isfile(filepath):
        mon_key_output = open(filepath, "r")
        if mon_key_output:
            keyrings['mon'] = {}
            for line in mon_key_output:
                attr = shlex.split(line)
                if attr:
                    if attr[0] == 'key':
                        keyrings['mon']['key'] = attr[2]
                    if attr[0] == 'caps' and 'caps' in keyrings['mon']:
                        keyrings['mon']['caps'][attr[1]] = attr[3]
                    elif attr[0] == 'caps' and 'caps' not in keyrings['mon']:
                        keyrings['mon']['caps'] = {}
                        keyrings['mon']['caps'][attr[1]] = attr[3]
            grain["ceph"]["ceph_keyring"] = keyrings

    return grain
