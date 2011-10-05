#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tests for dartrenderer.Render."""

import logging.config
import unittest
import dartrenderer
import idlnode
import idlparser


class DartRendererTestCase(unittest.TestCase):
  def _RunTest(self, input_text, expected_text):
    """Parses input, renders it and compares the results"""
    parser = idlparser.IDLParser(idlparser.FREMONTCUT_SYNTAX)
    idl_file = idlnode.IDLFile(parser.parse(input_text))
    interface = idl_file.modules[0].interfaces[0]
    output_text = dartrenderer.Render(interface, None)

    if output_text != expected_text:
      msg = """
EXPECTED:
%s
ACTUAL  :
%s
""" % (expected_text, output_text)
      self.fail(msg)

  def testRendering(self):
    input_text = """module M {
  interface I : @A J, K {
    getter attribute int get_attr;
    setter attribute int set_attr;

    [A,B=123] void function(in long x, in optional boolean y);

    const boolean CONST = 1;

    @A @B() @C(x) @D(x=1) @E(x,y=2)
    void something();

    snippet {This is a snippet};
  };
};"""

    expected_text = """interface I extends J, K {

  static final boolean CONST = 1;

  int get get_attr();

  void set set_attr(int value);

  void function(long x, boolean y = null);

  void something();

  This is a snippet
}
"""
    self._RunTest(input_text, expected_text)

if __name__ == '__main__':
  logging.config.fileConfig('logging.conf')
  if __name__ == '__main__':
    unittest.main()
