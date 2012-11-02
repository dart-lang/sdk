#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tests for emitter module."""

import logging.config
import unittest
import emitter


class EmitterTestCase(unittest.TestCase):

  def setUp(self):
    pass

  def tearDown(self):
    pass

  def check(self, e, expected):
    self.assertEquals(''.join(e.Fragments()), expected)

  def testExample(self):
    e = emitter.Emitter()
    body = e.Emit('$TYPE $NAME() {\n'
                  '  $!BODY\n'
                  '}\n',
                  TYPE='int', NAME='foo')
    body.Emit('return $VALUE;', VALUE='100')
    self.check(e,
               'int foo() {\n'
               '  return 100;\n'
               '}\n')

  def testTemplateErrorDuplicate(self):
    try:
      e = emitter.Emitter()
      b = e.Emit('$(A)$(!B)$(A)$(!B)')   # $(!B) is duplicated
    except RuntimeError, ex:
      return
    raise AssertionError('Expected error')

  def testTemplate1(self):
    e = emitter.Emitter()
    e.Emit('-$A+$B-$A+$B-', A='1', B='2')
    self.check(e, '-1+2-1+2-')

  def testTemplate2(self):
    e = emitter.Emitter()
    r = e.Emit('1$(A)2$(B)3$(A)4$(B)5', A='x', B='y')
    self.assertEquals(None, r)
    self.check(e, '1x2y3x4y5')

  def testTemplate3(self):
    e = emitter.Emitter()
    b = e.Emit('1$(A)2$(!B)3$(A)4$(B)5', A='x')
    b.Emit('y')
    self.check(e, '1x2y3x4y5')
    self.check(b, 'y')

  def testTemplate4(self):
    e = emitter.Emitter()
    (a, b) = e.Emit('$!A$!B$A$B')   # pair of holes.
    a.Emit('x')
    b.Emit('y')
    self.check(e, 'xyxy')

  def testMissing(self):
    # Behaviour of Undefined parameters depends on form.
    e = emitter.Emitter();
    e.Emit('$A $?B $(C) $(?D)')
    self.check(e, '$A  $(C) ')

  def testHoleScopes(self):
    e = emitter.Emitter()
    # Holes have scope.  They remember the bindings of the template application
    # in which they are created.  Create two holes which inherit bindings for C
    # and D.
    (a, b) = e.Emit('[$!A][$!B]$C$D$E', C='1', D='2')
    e.Emit('  $A$B$C$D')  # Bindings are local to the Emit
    self.check(e, '[][]12$E  $A$B$C$D')

    # Holes are not bound within holes.  That would too easily lead to infinite
    # expansions.
    a.Emit('$A$C$D')   # $A12
    b.Emit('$D$C$B')   # 21$B
    self.check(e, '[$A12][21$B]12$E  $A$B$C$D')
    # EmitRaw avoids interpolation.
    a.EmitRaw('$C$D')
    b.EmitRaw('$D$C')
    self.check(e, '[$A12$C$D][21$B$D$C]12$E  $A$B$C$D')

  def testFormat(self):
    self.assertEquals(emitter.Format('$A$B', A=1, B=2), '12')

if __name__ == '__main__':
  logging.config.fileConfig('logging.conf')
  if __name__ == '__main__':
    unittest.main()
