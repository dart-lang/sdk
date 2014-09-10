#!/usr/bin/python
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


"""This module provides maps and sets that report unused elements."""

_monitored_values = []


def FinishMonitoring(includeDart2jsOnly, logger):
  for value in _monitored_values:
    if value._dart2jsOnly and not includeDart2jsOnly:
      continue
    value.CheckUsage(logger)

class MonitoredCollection(object):
  def __init__(self, name, dart2jsOnly):
    self.name = name
    self._used_keys = set()
    self._dart2jsOnly = dart2jsOnly
    _monitored_values.append(self)

class Dict(MonitoredCollection):
  """Wrapper for a dict that reports unused keys."""

  def __init__(self, name, map, dart2jsOnly=False):
    super(Dict, self).__init__(name, dart2jsOnly)
    self._map = map

  def __getitem__(self, key):
    self._used_keys.add(key)
    return self._map[key]

  def __setitem__(self, key, value):
    self._map[key] = value

  def __contains__(self, key):
    self._used_keys.add(key)
    return key in self._map

  def __iter__(self):
    return self._map.__iter__()

  def get(self, key, default=None):
    self._used_keys.add(key)
    return self._map.get(key, default)

  def keys(self):
    return self._map.keys()

  def CheckUsage(self, logger):
    for v in sorted(self._map.keys()):
      if v not in self._used_keys:
        logger.warn('dict \'%s\' has unused key \'%s\'' % (self.name, v))


class Set(MonitoredCollection):
  """Wrapper for a set that reports unused keys."""

  def __init__(self, name, a_set, dart2jsOnly=False):
    super(Set, self).__init__(name, dart2jsOnly)
    self._set = a_set

  def __contains__(self, key):
    self._used_keys.add(key)
    return key in self._set

  def __iter__(self):
    return self._set.__iter__()

  def add(self, key):
    self._set += [key]

  def CheckUsage(self, logger):
    for v in sorted(self._set):
      if v not in self._used_keys:
        logger.warn('set \'%s\' has unused key \'%s\'' % (self.name, v))
