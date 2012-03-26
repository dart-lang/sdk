#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tests for emitter module."""

import logging.config
import unittest
import emitter
import multiemitter


class MultiEmitterTestCase(unittest.TestCase):

  def setUp(self):
    pass

  def tearDown(self):
    pass

  def check(self, m, expected):
    """Verifies that the multiemitter contains the expected contents.

    Expected is a list of (filename, content) pairs, sorted by filename.
    """
    files = []
    def _Collect(file, contents):
      files.append((file, ''.join(contents)))
    m.Flush(_Collect)
    self.assertEquals(expected, files)

  def testExample(self):
    m = multiemitter.MultiEmitter()
    e1 = m.FileEmitter('file1')
    e2 = m.FileEmitter('file2', 'key2')
    e1.Emit('Hi 1')
    e2.Emit('Hi 2')
    m.Find('key2').Emit('Bye 2')
    self.check(m,
               [('file1', 'Hi 1'),
                ('file2', 'Hi 2Bye 2') ])

if __name__ == '__main__':
  logging.config.fileConfig('logging.conf')
  if __name__ == '__main__':
    unittest.main()
