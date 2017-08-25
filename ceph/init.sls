include:
{% if pillar.ceph.mon is defined %}
- ceph.mon
{% endif %}
{% if pillar.ceph.osd is defined %}
- ceph.osd
{% endif %}
{% if pillar.ceph.setup is defined %}
- ceph.setup
{% endif %}
{% if pillar.ceph.client is defined %}
- ceph.client
{% endif %}
{% if pillar.ceph.radosgw is defined %}
- ceph.radosgw
{% endif %}
{% if pillar.ceph.monitoring is defined %}
- ceph.monitoring
{% endif %}
