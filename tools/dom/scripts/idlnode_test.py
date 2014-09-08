#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import idlnode
import idlparser
import logging.config
import sys
import unittest


class IDLNodeTestCase(unittest.TestCase):

  def _run_test(self, syntax, content, expected):
    """Utility run tests and prints extra contextual information.

    Args:
      syntax -- IDL grammar to use (either idlparser.WEBKIT_SYNTAX,
        WEBIDL_SYNTAX or FREMONTCUT_SYNTAX). If None, will run
        multiple tests, each with a different syntax.
      content -- input text for the parser.
      expected -- expected parse result.
    """
    if syntax is None:
      self._run_test(idlparser.WEBIDL_SYNTAX, content, expected)
      self._run_test(idlparser.WEBKIT_SYNTAX, content, expected)
      self._run_test(idlparser.FREMONTCUT_SYNTAX, content, expected)
      return

    actual = None
    error = None
    ast = None
    parseResult = None
    try:
      parser = idlparser.IDLParser(syntax)
      ast = parser.parse(content)
      node = idlnode.IDLFile(ast)
      actual = node.to_dict() if node else None
    except SyntaxError, e:
      error = e
      pass
    if actual == expected:
      return
    else:
      msg = '''
SYNTAX  : %s
CONTENT :
%s
EXPECTED:
%s
ACTUAL  :
%s
ERROR   : %s
AST   :
%s
      ''' % (syntax, content, expected, actual, error, ast)
      self.fail(msg)

  def test_empty_module(self):
    self._run_test(
      None,
      'module TestModule {};',
      {'modules': [{'id': 'TestModule'}]})

  def test_empty_interface(self):
    self._run_test(
      None,
      'module TestModule { interface Interface1 {}; };',
      {'modules': [{'interfaces': [{'javascript_binding_name': 'Interface1', 'doc_js_name': 'Interface1', 'id': 'Interface1'}], 'id': 'TestModule'}]})

  def test_gcc_preprocessor(self):
    self._run_test(
      idlparser.WEBKIT_SYNTAX,
      '#if 1\nmodule TestModule {};\n#endif\n',
      {'modules': [{'id': 'TestModule'}]})

  def test_extended_attributes(self):
    self._run_test(
      idlparser.WEBKIT_SYNTAX,
      'module M { interface [ExAt1, ExAt2] I {};};',
      {'modules': [{'interfaces': [{'javascript_binding_name': 'I', 'doc_js_name': 'I', 'ext_attrs': {'ExAt1': None, 'ExAt2': None}, 'id': 'I'}], 'id': 'M'}]})

  def test_implements_statement(self):
    self._run_test(
      idlparser.WEBIDL_SYNTAX,
      'module M { X implements Y; };',
      {'modules': [{'implementsStatements': [{'implementor': {'id': 'X'}, 'implemented': {'id': 'Y'}}], 'id': 'M'}]})

  def test_attributes(self):
    self._run_test(
      idlparser.WEBIDL_SYNTAX,
      '''interface I {
        attribute long a1;
        readonly attribute DOMString a2;
        attribute any a3;
      };''',
      {'interfaces': [{'javascript_binding_name': 'I', 'attributes': [{'type': {'id': 'long'}, 'id': 'a1', 'doc_js_interface_name': 'I'}, {'type': {'id': 'DOMString'}, 'is_read_only': True, 'id': 'a2', 'doc_js_interface_name': 'I'}, {'type': {'id': 'any'}, 'id': 'a3', 'doc_js_interface_name': 'I'}], 'id': 'I', 'doc_js_name': 'I'}]})

  def test_operations(self):
    self._run_test(
      idlparser.WEBIDL_SYNTAX,
      '''interface I {
        [ExAttr] t1 op1();
        t2 op2(in int arg1, in long arg2);
        getter any item(in long index);
        stringifier name();
      };''',
      {'interfaces': [{'operations': [{'doc_js_interface_name': 'I', 'type': {'id': 't1'}, 'ext_attrs': {'ExAttr': None}, 'id': 'op1'}, {'doc_js_interface_name': 'I', 'type': {'id': 't2'}, 'id': 'op2', 'arguments': [{'type': {'id': 'int'}, 'id': 'arg1'}, {'type': {'id': 'long'}, 'id': 'arg2'}]}, {'specials': ['getter'], 'doc_js_interface_name': 'I', 'type': {'id': 'any'}, 'id': 'item', 'arguments': [{'type': {'id': 'long'}, 'id': 'index'}]}, {'is_stringifier': True, 'type': {'id': 'name'}, 'doc_js_interface_name': 'I'}], 'javascript_binding_name': 'I', 'id': 'I', 'doc_js_name': 'I'}]})

  def test_constants(self):
    self._run_test(
      None,
      '''interface I {
        const long c1 = 0;
        const long c2 = 1;
        const long c3 = 0x01;
        const long c4 = 10;
        const boolean b1 = false;
        const boolean b2 = true;
      };''',
      {'interfaces': [{'javascript_binding_name': 'I', 'doc_js_name': 'I', 'id': 'I', 'constants': [{'type': {'id': 'long'}, 'id': 'c1', 'value': '0', 'doc_js_interface_name': 'I'}, {'type': {'id': 'long'}, 'id': 'c2', 'value': '1', 'doc_js_interface_name': 'I'}, {'type': {'id': 'long'}, 'id': 'c3', 'value': '0x01', 'doc_js_interface_name': 'I'}, {'type': {'id': 'long'}, 'id': 'c4', 'value': '10', 'doc_js_interface_name': 'I'}, {'type': {'id': 'boolean'}, 'id': 'b1', 'value': 'false', 'doc_js_interface_name': 'I'}, {'type': {'id': 'boolean'}, 'id': 'b2', 'value': 'true', 'doc_js_interface_name': 'I'}]}]})

  def test_annotations(self):
    self._run_test(
      idlparser.FREMONTCUT_SYNTAX,
      '@Ano1 @Ano2() @Ano3(x=1) @Ano4(x,y=2) interface I {};',
      {'interfaces': [{'javascript_binding_name': 'I', 'doc_js_name': 'I', 'id': 'I', 'annotations': {'Ano4': {'y': '2', 'x': None}, 'Ano1': {}, 'Ano2': {}, 'Ano3': {'x': '1'}}}]})
    self._run_test(
      idlparser.FREMONTCUT_SYNTAX,
      '''interface I : @Ano1 J {
        @Ano2 attribute int someAttr;
        @Ano3 void someOp();
        @Ano3 const int someConst = 0;
      };''',
      {'interfaces': [{'operations': [{'annotations': {'Ano3': {}}, 'type': {'id': 'void'}, 'id': 'someOp', 'doc_js_interface_name': 'I'}], 'javascript_binding_name': 'I', 'parents': [{'type': {'id': 'J'}, 'annotations': {'Ano1': {}}}], 'attributes': [{'annotations': {'Ano2': {}}, 'type': {'id': 'int'}, 'id': 'someAttr', 'doc_js_interface_name': 'I'}], 'doc_js_name': 'I', 'id': 'I', 'constants': [{'annotations': {'Ano3': {}}, 'type': {'id': 'int'}, 'id': 'someConst', 'value': '0', 'doc_js_interface_name': 'I'}]}]})

  def test_inheritance(self):
    self._run_test(
      None,
      'interface Shape {}; interface Rectangle : Shape {}; interface Square : Rectangle, Shape {};',
      {'interfaces': [{'javascript_binding_name': 'Shape', 'doc_js_name': 'Shape', 'id': 'Shape'}, {'javascript_binding_name': 'Rectangle', 'doc_js_name': 'Rectangle', 'parents': [{'type': {'id': 'Shape'}}], 'id': 'Rectangle'}, {'javascript_binding_name': 'Square', 'doc_js_name': 'Square', 'parents': [{'type': {'id': 'Rectangle'}}, {'type': {'id': 'Shape'}}], 'id': 'Square'}]})

if __name__ == "__main__":
  logging.config.fileConfig("logging.conf")
  if __name__ == '__main__':
    unittest.main()
