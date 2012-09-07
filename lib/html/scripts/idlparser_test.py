#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import idlparser
import logging.config
import sys
import unittest


class IDLParserTestCase(unittest.TestCase):

  def _run_test(self, syntax, content, expected):
    """Utility for running a IDL parsing tests and comparing results.

    Program exits (sys.exit) if expected does not match actual.

    Args:
      syntax -- IDL grammar to use (either idlparser.WEBKIT_SYNTAX,
        WEBIDL_SYNTAX or FREMONTCUT_SYNTAX). If None, will run
        multiple tests, each with a different syntax.
      content -- input text for the parser.
      expected -- expected parse result.
    """

    all_syntaxes = {idlparser.WEBIDL_SYNTAX: 'Web IDL',
            idlparser.WEBKIT_SYNTAX: 'WebKit',
            idlparser.FREMONTCUT_SYNTAX: 'FremontCut'}

    if syntax is None:
      for syntax in all_syntaxes:
        self._run_test(syntax, content, expected)
      return

    if syntax not in all_syntaxes:
      raise RuntimeError('Unexpected syntax %s' % syntax)

    actual = None
    error = None
    try:
      parser = idlparser.IDLParser(syntax)
      actual = parser.parse(content)
    except SyntaxError, e:
      error = e
      pass
    if actual != expected:
      self.fail('''
SYNTAX  : %s
CONTENT :
%s
EXPECTED:
%s
ACTUAL  :
%s
ERROR   : %s''' % (all_syntaxes[syntax], content, expected, actual, error))

  def test_empty_module(self):
    self._run_test(
      None,
      'module M {};',
      [('Module', [('Id', 'M')])])

  def test_empty_interface(self):
    self._run_test(
      None,
      'interface I {};',
      [('Interface', [('Id', 'I')])])

  def test_module_with_empty_interface(self):
    self._run_test(
      None,
      'module M { interface I {}; };',
      [('Module', [('Id', 'M'), ('Interface', [('Id', 'I')])])])

  # testing the gcc pre-processing
  def test_gcc_preprocessing(self):
    self._run_test(
      idlparser.WEBKIT_SYNTAX,
      '''
      #if 1
        module M1 {};
      #endif
      #if 0
        module M2 {};
      #endif
      ''',
      [('Module', [('Id', 'M1')])])

  def test_attribute_with_exceptoins(self):
    self._run_test(
      idlparser.WEBKIT_SYNTAX,
      '''interface I {
        attribute boolean A setter raises (E), getter raises (E);
      };''',
      [('Interface', [('Id', 'I'), ('Attribute', [('Type', [('BooleanType', None)]), ('Id', 'A'), ('SetRaises', [('ScopedName', 'E')]), ('GetRaises', [('ScopedName', 'E')])])])])

  def test_interface_with_extended_attributes(self):
    self._run_test(
      idlparser.WEBKIT_SYNTAX,
      'interface [ExAt1, ExAt2] I {};',
      [('Interface', [('ExtAttrs', [('ExtAttr', [('Id', 'ExAt1')]), ('ExtAttr', [('Id', 'ExAt2')])]), ('Id', 'I')])])

  def test_implements_statement(self):
    self._run_test(
      idlparser.WEBIDL_SYNTAX,
      'X implements Y;',
      [('ImplStmt', [('ImplStmtImplementor', ('ScopedName', 'X')), ('ImplStmtImplemented', ('ScopedName', 'Y'))])])

  def test_operation(self):
    self._run_test(
      None,
      'interface I { boolean func(); };',
      [('Interface', [('Id', 'I'), ('Operation', [('ReturnType', [('BooleanType', None)]), ('Id', 'func')])])])

  def test_attribute_types(self):
    self._run_test(
      None,
      '''interface I {
        attribute boolean boolAttr;
        attribute DOMString strAttr;
        attribute SomeType someAttr;
      };''',
      [('Interface', [('Id', 'I'), ('Attribute', [('Type', [('BooleanType', None)]), ('Id', 'boolAttr')]), ('Attribute', [('Type', [('ScopedName', 'DOMString')]), ('Id', 'strAttr')]), ('Attribute', [('Type', [('ScopedName', 'SomeType')]), ('Id', 'someAttr')])])])

  def test_constants(self):
    self._run_test(
      None,
      '''interface I {
        const long c1 = 0;
        const long c2 = 1;
        const long c3 = 0x01;
        const long c4 = 10;
        const boolean b1 = true;
        const boolean b1 = false;
      };''',
      [('Interface', [('Id', 'I'), ('Const', [('Type', [('LongType', None)]), ('Id', 'c1'), ('ConstExpr', '0')]), ('Const', [('Type', [('LongType', None)]), ('Id', 'c2'), ('ConstExpr', '1')]), ('Const', [('Type', [('LongType', None)]), ('Id', 'c3'), ('ConstExpr', '0x01')]), ('Const', [('Type', [('LongType', None)]), ('Id', 'c4'), ('ConstExpr', '10')]), ('Const', [('Type', [('BooleanType', None)]), ('Id', 'b1'), ('ConstExpr', 'true')]), ('Const', [('Type', [('BooleanType', None)]), ('Id', 'b1'), ('ConstExpr', 'false')])])])

  def test_inheritance(self):
    self._run_test(
      None,
      '''
      interface Shape {};
      interface Rectangle : Shape {};
      interface Square : Rectangle, Shape {};
      ''',
      [('Interface', [('Id', 'Shape')]), ('Interface', [('Id', 'Rectangle'), ('ParentInterface', [('InterfaceType', ('ScopedName', 'Shape'))])]), ('Interface', [('Id', 'Square'), ('ParentInterface', [('InterfaceType', ('ScopedName', 'Rectangle'))]), ('ParentInterface', [('InterfaceType', ('ScopedName', 'Shape'))])])])

  def test_annotations(self):
    self._run_test(
      idlparser.FREMONTCUT_SYNTAX,
      '@Ano1 @Ano2() @Ano3(x) @Ano4(x=1,y=2) interface I {};',
      [('Interface', [('Annotation', [('Id', 'Ano1')]), ('Annotation', [('Id', 'Ano2')]), ('Annotation', [('Id', 'Ano3'), ('AnnotationArg', [('Id', 'x')])]), ('Annotation', [('Id', 'Ano4'), ('AnnotationArg', [('Id', 'x'), ('AnnotationArgValue', '1')]), ('AnnotationArg', [('Id', 'y'), ('AnnotationArgValue', '2')])]), ('Id', 'I')])])


if __name__ == "__main__":
  logging.config.fileConfig("logging.conf")
  if __name__ == '__main__':
    unittest.main()
