#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import logging.config
import pprint
import re
import sys
import unittest
from pegparser import *


class PegParserTestCase(unittest.TestCase):

  def _run_test(self, grammar, text, expected,
          strings_are_tokens=False, whitespace_rule=None):
    """Utility for running a parser test and comparing results.

    Program exits (sys.exit) if expected does not match actual.

    Args:
      grammar -- the root rule to be used by the parser.
      text -- the text to parse.
      expected -- the expected abstract syntax tree. None means
        failure is expected.
      strings_are_tokens -- whether strings are treated as tokens.
      whitespace_rule -- the rule used for matching whitespace.
        Default is None, which means that no whitespace is tolerated.
    """
    parser = PegParser(grammar, whitespace_rule,
               strings_are_tokens=strings_are_tokens)
    actual = None
    error = None
    try:
      actual = parser.parse(text)
    except SyntaxError, e:
      error = e
      pass

    if actual != expected:
      msg = '''
CONTENT:
%s
EXPECTED:
%s
ACTUAL:
%s
ERROR: %s''' % (text, pprint.pformat(expected), pprint.pformat(actual), error)
      self.fail(msg)

  def test_sequence(self):
    sequence = SEQUENCE('A', 'BB', 'C')
    self._run_test(grammar=sequence, text='ABBC', expected=['A', 'BB', 'C'])
    self._run_test(grammar=sequence, text='BBAC', expected=None)
    # Syntax Sugar
    sequence = ['A', 'BB', 'C']
    self._run_test(grammar=sequence, text='ABBC', expected=['A', 'BB', 'C'])
    self._run_test(grammar=sequence, text='BBAC', expected=None)

  def test_regex(self):
    regex = re.compile(r'[A-Za-z]*')
    self._run_test(grammar=regex, text='AaBb', expected='AaBb')
    self._run_test(grammar=regex, text='0AaBb', expected=None)
    self._run_test(grammar=regex, text='Aa0Bb', expected=None)

  def test_function(self):
    def Func():
      return 'ABC'
    self._run_test(grammar=Func, text='ABC', expected=('Func', 'ABC'))
    self._run_test(grammar=Func, text='XYZ', expected=None)

  def test_function_label(self):
    def func():
      return 'ABC'

    def _func():
      return 'ABC'

    self._run_test(grammar=func, text='ABC', expected=('func', 'ABC'))
    self._run_test(grammar=_func, text='ABC', expected='ABC')

  def test_label(self):
    sequence = [TOKEN('def'), LABEL('funcName', re.compile(r'[a-z0-9]*')),
          TOKEN('():')]
    self._run_test(grammar=sequence, text='def f1():',
      whitespace_rule=' ', expected=[('funcName', 'f1')])
    self._run_test(grammar=sequence, text='def f2():',
      whitespace_rule=' ', expected=[('funcName', 'f2')])

  def test_or(self):
    grammer = OR('A', 'B')
    self._run_test(grammar=grammer, text='A', expected='A')
    self._run_test(grammar=grammer, text='B', expected='B')
    self._run_test(grammar=grammer, text='C', expected=None)

  def test_maybe(self):
    seq = ['A', MAYBE('B'), 'C']
    self._run_test(grammar=seq, text='ABC', expected=['A', 'B', 'C'])
    self._run_test(grammar=seq, text='ADC', expected=None)
    self._run_test(grammar=seq, text='AC', expected=['A', 'C'])
    self._run_test(grammar=seq, text='AB', expected=None)

  def test_many(self):
    seq = ['A', MANY('B'), 'C']
    self._run_test(grammar=seq, text='ABC', expected=['A', 'B', 'C'])
    self._run_test(grammar=seq, text='ABBBBC',
      expected=['A', 'B', 'B', 'B', 'B', 'C'])
    self._run_test(grammar=seq, text='AC', expected=None)

  def test_many_with_separator(self):
    letter = OR('A', 'B', 'C')

    def _gram():
      return [letter, MAYBE([TOKEN(','), _gram])]

    self._run_test(grammar=_gram, text='A,B,C,B',
      expected=['A', 'B', 'C', 'B'])
    self._run_test(grammar=_gram, text='A B C', expected=None)
    shortergrammar = MANY(letter, TOKEN(','))
    self._run_test(grammar=shortergrammar, text='A,B,C,B',
      expected=['A', 'B', 'C', 'B'])
    self._run_test(grammar=shortergrammar, text='A B C', expected=None)

  def test_raise(self):
    self._run_test(grammar=['A', 'B'], text='AB',
      expected=['A', 'B'])
    try:
      self._run_test(grammar=['A', 'B', RAISE('test')], text='AB',
        expected=None)
      print 'Expected RuntimeError'
      sys.exit(-1)
    except RuntimeError, e:
      return

  def test_whitespace(self):
    gram = MANY('A')
    self._run_test(grammar=gram, text='A A  A', expected=None)
    self._run_test(grammar=gram, whitespace_rule=' ', text='A A  A',
      expected=['A', 'A', 'A'])

  def test_math_expression_syntax(self):
    operator = LABEL('op', OR('+', '-', '/', '*'))
    literal = LABEL('num', re.compile(r'[0-9]+'))

    def _exp():
      return MANY(OR(literal, [TOKEN('('), _exp, TOKEN(')')]),
            separator=operator)

    self._run_test(grammar=_exp,
      text='(1-2)+3*((4*5)*6)+(7+8/9)-10',
      expected=[[('num', '1'), ('op', '-'), ('num', '2')],
        ('op', '+'),
        ('num', '3'),
        ('op', '*'),
        [[('num', '4'), ('op', '*'), ('num', '5')],
          ('op', '*'), ('num', '6')],
        ('op', '+'),
        [('num', '7'), ('op', '+'), ('num', '8'),
         ('op', '/'), ('num', '9')],
        ('op', '-'),
        ('num', '10')])

  def test_mini_language(self):
    def name():
      return re.compile(r'[a-z]+')

    def var_decl():
      return ['var', name, ';']

    def func_invoke():
      return [name, '(', ')', ';']

    def func_body():
      return MANY(OR(var_decl, func_invoke))

    def func_decl():
      return ['function', name, '(', ')', '{', func_body, '}']

    def args():
      return MANY(name, ',')

    def program():
      return MANY(OR(var_decl, func_decl))

    self._run_test(grammar=program,
      whitespace_rule=OR('\n', ' '),
      strings_are_tokens=True,
      text='var x;\nfunction f(){\n  var y;\n  g();\n}\n',
      expected=('program',[
             ('var_decl', [('name', 'x')]),
             ('func_decl', [('name', 'f'), ('func_body', [
              ('var_decl', [('name', 'y')]),
              ('func_invoke', [('name', 'g')])])])]))


if __name__ == "__main__":
  logging.config.fileConfig("logging.conf")
  if __name__ == '__main__':
    unittest.main()
