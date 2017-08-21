import pytest

testinfra_hosts = ['salt://I@ceph:mon']

@pytest.mark.parametrize('cmd', [
    'ceph health',
    'ceph status',
    'ceph osd tree',
    'ceph df',
    'ceph osd pool ls',
    'ceph auth list'
])
def test_command(host, cmd):
    cmd = host.run(cmd)

    print(cmd.stdout)
    assert cmd.rc == 0

