#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This entry point runs all script tests."""

import logging.config
import unittest

if __name__ == '__main__':
  logging.config.fileConfig('logging.conf')
  suite = unittest.TestLoader().loadTestsFromNames([
      'templateloader_test',
      'pegparser_test',
      'idlparser_test',
      'idlnode_test',
      'idlrenderer_test',
      'database_test',
      'databasebuilder_test',
      'emitter_test',
      'dartgenerator_test',
      'multiemitter_test'])
  unittest.TextTestRunner().run(suite)
