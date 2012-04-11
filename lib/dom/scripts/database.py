#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Module to manage IDL files."""

import copy
import pickle
import logging
import os
import os.path
import shutil
import idlnode
import idlparser
import idlrenderer

_logger = logging.getLogger('database')


class Database(object):
  """The Database class manages a collection of IDL files stored
  inside a directory.

  Each IDL is describing a single interface. The IDL files are written in the
  FremontCut syntax, which is derived from the Web IDL syntax and includes
  annotations.

  Database operations include adding, updating and removing IDL files.
  """

  def __init__(self, root_dir):
    """Initializes a Database over a given directory.

    Args:
      root_dir -- a directory. If directory does not exist, it will
      be created.
    """
    self._root_dir = root_dir
    if not os.path.exists(root_dir):
      _logger.debug('creating root directory %s' % root_dir)
      os.makedirs(root_dir)
    self._all_interfaces = {}
    self._interfaces_to_delete = []
    self._idlparser = idlparser.IDLParser(idlparser.FREMONTCUT_SYNTAX)

  def Clone(self):
    new_database = Database(self._root_dir)
    new_database._all_interfaces = copy.deepcopy(self._all_interfaces)
    new_database._interfaces_to_delete = copy.deepcopy(
        self._interfaces_to_delete)
    return new_database

  def Delete(self):
    """Deletes the database by deleting its directory"""
    if os.path.exists(self._root_dir):
      shutil.rmtree(self._root_dir)
    # reset in-memory constructs
    self._all_interfaces = {}

  def _ScanForInterfaces(self):
    """Iteratores over the database files and lists all interface names.

    Return:
      A list of interface names.
    """
    res = []

    def Visitor(_, dirname, names):
      for name in names:
        if os.path.isfile(os.path.join(dirname, name)):
          root, ext = os.path.splitext(name)
          if ext == '.idl':
            res.append(root)

    os.path.walk(self._root_dir, Visitor, None)
    return res

  def _FilePath(self, interface_name):
    """Calculates the file path that a given interface should
    be saved to.

    Args:
      interface_name -- the name of the interface.
    """
    return os.path.join(self._root_dir, '%s.idl' % interface_name)

  def _LoadInterfaceFile(self, interface_name):
    """Loads an interface from the database.

    Returns:
      An IDLInterface instance or None if the interface is not found.
    Args:
      interface_name -- the name of the interface.
    """
    file_name = self._FilePath(interface_name)
    _logger.info('loading %s' % file_name)
    if not os.path.exists(file_name):
      return None

    f = open(file_name, 'r')
    content = f.read()
    f.close()

    # Parse file:
    idl_file = idlnode.IDLFile(self._idlparser.parse(content), file_name)

    if not idl_file.interfaces:
      raise RuntimeError('No interface found in %s' % file_name)
    elif len(idl_file.interfaces) > 1:
      raise RuntimeError('Expected one interface in %s' % file_name)

    interface = idl_file.interfaces[0]
    self._all_interfaces[interface_name] = interface
    return interface

  def Load(self):
    """Loads all interfaces into memory.
    """
    # FIXME: Speed this up by multi-threading.
    for (interface_name) in self._ScanForInterfaces():
      self._LoadInterfaceFile(interface_name)
    self.Cache()

  def Cache(self):
    """Serialize the database using pickle for faster startup in the future
    """
    output_file = open(os.path.join(self._root_dir, 'cache.pickle'), 'wb')
    pickle.dump(self._all_interfaces, output_file)
    pickle.dump(self._interfaces_to_delete, output_file)

  def LoadFromCache(self):
    """Deserialize the database using pickle for fast startup
    """
    input_file_name = os.path.join(self._root_dir, 'cache.pickle')
    if not os.path.isfile(input_file_name):
      self.Load()
      return
    input_file = open(input_file_name, 'rb')
    self._all_interfaces = pickle.load(input_file)
    self._interfaces_to_delete = pickle.load(input_file)
    input_file.close()

  def Save(self):
    """Saves all in-memory interfaces into files."""
    for interface in self._all_interfaces.values():
      self._SaveInterfaceFile(interface)
    for interface_name in self._interfaces_to_delete:
      self._DeleteInterfaceFile(interface_name)

  def _SaveInterfaceFile(self, interface):
    """Saves an interface into the database.

    Args:
      interface -- an IDLInterface instance.
    """

    interface_name = interface.id

    # Actual saving
    file_path = self._FilePath(interface_name)
    _logger.debug('writing %s' % file_path)

    dir_name = os.path.dirname(file_path)
    if not os.path.exists(dir_name):
      _logger.debug('creating directory %s' % dir_name)
      os.mkdir(dir_name)

    # Render the IDLInterface object into text.
    text = idlrenderer.render(interface)

    f = open(file_path, 'w')
    f.write(text)
    f.close()

  def HasInterface(self, interface_name):
    """Returns True if the interface is in memory"""
    return interface_name in self._all_interfaces

  def GetInterface(self, interface_name):
    """Returns an IDLInterface corresponding to the interface_name
    from memory.

    Args:
      interface_name -- the name of the interface.
    """
    if interface_name not in self._all_interfaces:
      raise RuntimeError('Interface %s is not loaded' % interface_name)
    return self._all_interfaces[interface_name]

  def AddInterface(self, interface):
    """Returns an IDLInterface corresponding to the interface_name
    from memory.

    Args:
      interface -- the name of the interface.
    """
    interface_name = interface.id
    if interface_name in self._all_interfaces:
      raise RuntimeError('Interface %s already exists' % interface_name)
    self._all_interfaces[interface_name] = interface

  def GetInterfaces(self):
    """Returns a list of all loaded interfaces."""
    res = []
    for _, interface in sorted(self._all_interfaces.items()):
      res.append(interface)
    return res

  def DeleteInterface(self, interface_name):
    """Deletes an interface from the database. File is deleted when
    Save() is called.

    Args:
      interface_name -- the name of the interface.
    """
    if interface_name not in self._all_interfaces:
      raise RuntimeError('Interface %s not found' % interface_name)
    self._interfaces_to_delete.append(interface_name)
    del self._all_interfaces[interface_name]

  def _DeleteInterfaceFile(self, interface_name):
    """Actual file deletion"""
    file_path = self._FilePath(interface_name)
    if os.path.exists(file_path):
      _logger.debug('deleting %s' % file_path)
      os.remove(file_path)
