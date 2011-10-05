#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tests for database module."""

import logging.config
import os.path
import shutil
import tempfile
import unittest
import database
import idlnode
import idlparser


class DatabaseTestCase(unittest.TestCase):

  def _ParseInterface(self, content):
    ast = self._idl_parser.parse(content)
    return idlnode.IDLFile(ast).interfaces[0]

  def _ListInterfaces(self, db):
    res = []
    for interface in db.GetInterfaces():
      name = interface.id
      res.append(name)
    return res

  def setUp(self):
    self._idl_parser = idlparser.IDLParser(idlparser.FREMONTCUT_SYNTAX)

    working_dir = tempfile.mkdtemp()
    self._database_dir = os.path.join(working_dir, 'database')
    self.assertFalse(os.path.exists(self._database_dir))

    # Create database and add one interface.
    db = database.Database(self._database_dir)
    interface = self._ParseInterface('interface I1 {};')
    db.AddInterface(interface)
    db.Save()
    self.assertTrue(
        os.path.exists(os.path.join(self._database_dir, 'I1.idl')))

  def tearDown(self):
    shutil.rmtree(self._database_dir)

  def testCreate(self):
    self.assertTrue(os.path.exists(self._database_dir))

  def testListInterfaces(self):
    db = database.Database(self._database_dir)
    db.Load()
    self.assertEquals(self._ListInterfaces(db), ['I1'])

  def testHasInterface(self):
    db = database.Database(self._database_dir)
    db.Load()
    self.assertTrue(db.HasInterface('I1'))
    self.assertFalse(db.HasInterface('I2'))

  def testAddInterface(self):
    db = database.Database(self._database_dir)
    db.Load()
    interface = self._ParseInterface('interface I2 {};')
    db.AddInterface(interface)
    db.Save()
    self.assertTrue(
        os.path.exists(os.path.join(self._database_dir, 'I2.idl')))
    self.assertEquals(self._ListInterfaces(db),
                      ['I1', 'I2'])

  def testDeleteInterface(self):
    db = database.Database(self._database_dir)
    db.Load()
    db.DeleteInterface('I1')
    db.Save()
    self.assertFalse(
        os.path.exists(os.path.join(self._database_dir, 'I1.idl')))
    self.assertEquals(self._ListInterfaces(db), [])

  def testGetInterface(self):
    db = database.Database(self._database_dir)
    db.Load()
    interface = db.GetInterface('I1')
    self.assertEquals(interface.id, 'I1')


if __name__ == '__main__':
  logging.config.fileConfig('logging.conf')
  if __name__ == '__main__':
    unittest.main()
