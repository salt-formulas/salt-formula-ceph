# -*- coding: utf-8 -*-
'''
Module to provide ceph control with salt.
:depends:   - ceph_cfg Python module
.. versionadded:: 2017.7.0
'''
# Import Python Libs
from __future__ import absolute_import
import logging


log = logging.getLogger(__name__)

__virtualname__ = 'ceph_ng'


def __virtual__():
    return __virtualname__
