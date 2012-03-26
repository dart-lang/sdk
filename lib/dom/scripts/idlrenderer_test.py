#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import idlnode
import idlparser
import idlrenderer
import logging.config
import unittest


class IDLRendererTestCase(unittest.TestCase):

  def _run_test(self, input_text, expected_text):
    """Parses input, renders it and compares the results"""
    parser = idlparser.IDLParser(idlparser.FREMONTCUT_SYNTAX)
    idl_file = idlnode.IDLFile(parser.parse(input_text))
    output_text = idlrenderer.render(idl_file)

    if output_text != expected_text:
      msg = '''
EXPECTED:
%s
ACTUAL  :
%s
''' % (expected_text, output_text)
      self.fail(msg)

  def test_rendering(self):
    input_text = \
'''module M {
  [Constructor(long x)] interface I : @A J, K {
    attribute int attr;
    readonly attribute long attr2;
    getter attribute int get_attr;
    setter attribute int set_attr;

    [A,B=123] void function(in long x, in optional boolean y);

    const boolean CONST = 1;

    @A @B() @C(x) @D(x=1) @E(x,y=2)
    void something();
  };
};
@X module M2 {
  @Y interface I {};
};'''

    expected_text = \
'''module M {
  [Constructor(in long x)]
  interface I :
      @A J,
      K {

    /* Constants */
    const boolean CONST = 1;

    /* Attributes */
    attribute int attr;
    attribute long attr2;
    getter attribute int get_attr;
    setter attribute int set_attr;

    /* Operations */
    [A, B=123] void function(in long x, in optional boolean y);
    @A @B @C(x) @D(x=1) @E(x, y=2) void something();
  };
};
@X module M2 {
  @Y
  interface I {
  };
};
'''
    self._run_test(input_text, expected_text)

if __name__ == "__main__":
  logging.config.fileConfig("logging.conf")
  if __name__ == '__main__':
    unittest.main()
