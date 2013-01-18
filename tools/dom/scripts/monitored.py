#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides maps and sets that report unused elements."""

_monitored_values = []


def FinishMonitoring():
  for value in _monitored_values:
    value.CheckUsage()

class MonitoredCollection(object):
  def __init__(self, name):
    self.name = name
    self._used_keys = set()
    _monitored_values.append(self)

class Dict(MonitoredCollection):
  """Wrapper for a read-only dict that reports unused keys."""

  def __init__(self, name, map):
    super(Dict, self).__init__(name)
    self._map = map

  def __getitem__(self, key):
    self._used_keys.add(key)
    return self._map[key]

  def __contains__(self, key):
    self._used_keys.add(key)
    return key in self._map

  def __iter__(self):
    return self._map.__iter__()

  def get(self, key, default=None):
    self._used_keys.add(key)
    return self._map.get(key, default)

  def CheckUsage(self):
    for v in sorted(self._map.keys()):
      if v not in self._used_keys:
        print "dict '%s' has unused key '%s'" % (self.name, v)


class Set(MonitoredCollection):
  """Wrapper for a read-only set that reports unused keys."""

  def __init__(self, name, a_set):
    super(Set, self).__init__(name)
    self._set = a_set

  def __contains__(self, key):
    self._used_keys.add(key)
    return key in self._set

  def CheckUsage(self):
    for v in sorted(self._set):
      if v not in self._used_keys:
        print "set '%s' has unused key '%s'" % (self.name, v)
