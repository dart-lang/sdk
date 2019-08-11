#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Unit tests for make_bundle.py."""

import os
from os import path
import shutil
import subprocess
import sys
import tempfile
import unittest

import make_bundle


class BundleMakerTest(unittest.TestCase):
    """Unit test class for BundleMaker."""

    def setUp(self):
        self._tempdir = tempfile.mkdtemp()
        self._top_dir = path.normpath(
            path.join(path.dirname(sys.argv[0]), os.pardir))
        self._dest = path.join(self._tempdir, 'new_bundle')

    def tearDown(self):
        shutil.rmtree(self._tempdir)

    def testBuildOptions(self):
        op = make_bundle.BundleMaker.BuildOptions()
        op.parse_args(args=[])

    def testCheckOptions(self):
        op = make_bundle.BundleMaker.BuildOptions()
        options = make_bundle.BundleMaker.CheckOptions(op, self._top_dir,
                                                       ['--dest', self._dest])
        self.failUnless(path.exists(self._dest))
        os.rmdir(self._dest)
        self.assertEquals(self._dest, options['dest'])
        self.assertEquals(self._top_dir, options['top_dir'])
        self.failIf(options['verbose'])
        self.failIf(options['skip_build'])
        options = make_bundle.BundleMaker.CheckOptions(
            op, self._top_dir, ['--dest', self._dest, '-v'])
        self.failUnless(path.exists(self._dest))
        self.assertEquals(self._dest, options['dest'])
        self.assertEquals(self._top_dir, options['top_dir'])
        self.failUnless(options['verbose'])
        self.failIf(options['skip_build'])

    def _RunCommand(self, *args):
        proc = subprocess.Popen(
            args,
            cwd=self._dest,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT)
        stdout = proc.communicate()[0]
        self.assertEqual(
            0, proc.wait(), msg='%s\n%s' % (' '.join(args), stdout))

    def testMakeBundle(self):
        os.mkdir(self._dest)
        maker = make_bundle.BundleMaker(dest=self._dest, top_dir=self._top_dir)
        self.assertEquals(0, maker.MakeBundle())
        commands = [
            './dart samples/hello.dart',
            './dart samples/deltablue.dart',
            './dart samples/mandelbrot.dart',
            './dart samples/towers.dart',
        ]
        for command in commands:
            args = command.split(' ')
            self._RunCommand(*args)
            args.append('--arch=dartc')
            self._RunCommand(*args)


if __name__ == '__main__':
    unittest.main()
