#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import logging.config
import unittest
import templateloader

class TemplateLoaderTestCase(unittest.TestCase):

  def _preprocess(self, input_text, conds):
    loader = templateloader.TemplateLoader('.', [], conds)
    return loader._Preprocess(input_text, '<file>')


  def _preprocess_test(self, input_text, conds, expected_text):
    output_text = self._preprocess(input_text, conds)
    if output_text != expected_text:
      msg = '''
EXPECTED:
%s
---
ACTUAL  :
%s
---''' % (expected_text, output_text)
      self.fail(msg)


  def _preprocess_error_test(self, input_text, conds, expected_message):
    threw = False
    try:
      output_text = self._preprocess(input_text, conds)
    except Exception, e:
      threw = True
      if str(e).find(expected_message) == -1:
        self.fail("'%s' does not contain '%s'" % (e, expected_message))
    if not threw:
      self.fail("missing error, expected '%s'" % expected_message)


  def test_freevar(self):
    input_text = '''$A
$B'''
    self._preprocess_test(input_text, {}, input_text)


  def test_ite1(self):
    input_text = '''
        aaa
        $if A
        bbb
        $else
        ccc
        $endif
        ddd
        '''
    self._preprocess_test(input_text, {'A':True},
        '''
        aaa
        bbb
        ddd
        ''')

  def test_ite2(self):
    input_text = '''
        aaa
        $if A
        bbb
        $else
        ccc
        $endif
        ddd
        '''
    self._preprocess_test(input_text, {'A':False},
        '''
        aaa
        ccc
        ddd
        ''')

  def test_if1(self):
    input_text = '''
       $if
       '''
    self._preprocess_error_test(input_text, {},
        '$if does not have single variable')

  def test_if2(self):
    input_text = '''
       $if A
       '''
    self._preprocess_error_test(input_text, {}, 'Unknown $if variable')

  def test_else1(self):
    input_text = '''
       $else
       '''
    self._preprocess_error_test(input_text, {}, '$else without $if')

  def test_else2(self):
    input_text = '''
       $if A
       $else
       $else
       '''
    self._preprocess_error_test(input_text, {'A':True}, 'Double $else')

  def test_eof1(self):
    input_text = '''
       $if A
       '''
    self._preprocess_error_test(input_text, {'A':True}, 'Unterminated')

  def test_eof2(self):
    input_text = '''
       $if A
       $else
       '''
    self._preprocess_error_test(input_text, {'A':True}, 'Unterminated')

if __name__ == "__main__":
  logging.config.fileConfig("logging.conf")
  if __name__ == '__main__':
    unittest.main()
