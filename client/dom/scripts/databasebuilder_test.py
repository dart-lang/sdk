#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import database
import idlparser
import logging.config
import os
import os.path
import shutil
import tempfile
import unittest
from databasebuilder import *


class DatabaseBuilderTestCase(unittest.TestCase):

  def _create_input(self, idl_file_name, content):
    file_name = os.path.join(self._input_dir, idl_file_name)
    f = open(file_name, 'w')
    f.write(content)
    f.close()
    return file_name

  def _assert_interface_exists(self, path):
    file_path = os.path.join(self._database_dir, path)
    self.assertTrue(os.path.exists(file_path))

  def _assert_content_equals(self, path, expected_content):
    def clean(content):
      return ' '.join(filter(len, map(str.strip, content.split('\n'))))
    file_path = os.path.join(self._database_dir, path)
    self.assertTrue(os.path.exists(file_path))
    f = open(file_path, 'r')
    actual_content = f.read()
    f.close()
    if clean(actual_content) != clean(expected_content):
      msg = '''
FILE: %s
EXPECTED:
%s
ACTUAL:
%s
''' % (file_path, expected_content, actual_content)
      self.fail(msg)

  def setUp(self):
    working_dir = tempfile.mkdtemp()
    self._database_dir = os.path.join(working_dir, 'database')
    self.assertFalse(os.path.exists(self._database_dir))

    self._input_dir = os.path.join(working_dir, 'inputdir')
    os.makedirs(self._input_dir)

    self._db = database.Database(self._database_dir)
    self.assertTrue(os.path.exists(self._database_dir))

    self._builder = DatabaseBuilder(self._db)

  def tearDown(self):
    shutil.rmtree(self._database_dir)

  def test_basic_import(self):
    file_name = self._create_input('input.idl', '''
      module M {
        interface I {
          attribute int a;
        };
      };''')
    self._builder.import_idl_file(file_name)
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_interface_exists('I.idl')

  def test_splitting(self):
    file_name = self._create_input('input.idl', '''
      module M {
        interface I {
          readonly attribute int a;
          int o(in int x, in optional int y);
        };
      };''')
    self._builder.import_idl_file(file_name)
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      interface I {
        /* Attributes */
        getter attribute int a;

        /* Operations */
        int o(in int x);
        int o(in int x, in int y);
      };''')

  def test_renames(self):
    file_name = self._create_input('input.idl', '''
      module M {
        [Constructor(in T x)] interface I {
          T op(T x);
          readonly attribute N::T attr;
        };
      };''')
    options = DatabaseBuilderOptions(type_rename_map={'I': 'i', 'T': 't'})
    self._builder.import_idl_file(file_name, options)
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('i.idl', '''
      [Constructor(in t x)] interface i {
        /* Attributes */
        getter attribute t attr;
        /* Operations */
        t op(in t x);
      };''')

  def test_type_defs(self):
    file_name = self._create_input('input.idl', '''
      module M {
        typedef T S;
        interface I : S {
          S op(S x);
          readonly attribute S attr;
        };
      };''')
    options = DatabaseBuilderOptions()
    self._builder.import_idl_file(file_name, options)
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      interface I :
        T {
        /* Attributes */
        getter attribute T attr;
        /* Operations */
        T op(in T x);
      };''')

  def test_merge(self):
    file_name1 = self._create_input('input1.idl', '''
      module M {
        interface I {
          const int CONST_BOTH = 0;
          const int CONST_ONLY_FIRST = 0;
          const int CONST_BOTH_DIFFERENT_VALUE = 0;

          readonly attribute int attr_only_first;
          readonly attribute int attr_both;
          readonly attribute int attr_both_readonly_difference;
          readonly attribute int attr_both_int_long_difference;

          int op_only_first();
          int op_both(int a);
          int op_both_optionals_difference(int a,
            in optional int b);
          int op_both_arg_rename(int arg);
        };
      };''')
    self._builder.import_idl_file(file_name1,
      DatabaseBuilderOptions(source='1st',
        idl_syntax=idlparser.FREMONTCUT_SYNTAX))
    file_name2 = self._create_input('input2.idl', '''
      module M {
        interface I {
          const int CONST_BOTH = 0;
          const int CONST_ONLY_SECOND = 0;
          const int CONST_BOTH_DIFFERENT_VALUE = 1;

          readonly attribute int attr_only_second;
          readonly attribute int attr_both;
          readonly attribute long attr_both_int_long_difference;
          attribute int attr_both_readonly_difference;

          int op_only_second();
          int op_both(int a);
          int op_both_optionals_difference(int a,
            optional boolean b);
          int op_both_arg_rename(int betterName);
        };
      };''')
    self._builder.import_idl_file(file_name2,
      DatabaseBuilderOptions(source='2nd',
        idl_syntax=idlparser.FREMONTCUT_SYNTAX))
    self._builder.set_same_signatures({'int': 'long'})
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      @1st(module=M) @2nd(module=M) interface I {
        /* Constants */
        @1st @2nd const int CONST_BOTH = 0;
        @1st const int CONST_BOTH_DIFFERENT_VALUE = 0;
        @2nd const int CONST_BOTH_DIFFERENT_VALUE = 1;
        @1st const int CONST_ONLY_FIRST = 0;
        @2nd const int CONST_ONLY_SECOND = 0;

        /* Attributes */
        @1st @2nd getter attribute int attr_both;
        @1st @2nd getter attribute int attr_both_int_long_difference;
        @1st @2nd getter attribute int attr_both_readonly_difference;
        @2nd setter attribute int attr_both_readonly_difference;
        @1st getter attribute int attr_only_first;
        @2nd getter attribute int attr_only_second;

        /* Operations */
        @1st @2nd int op_both(in t a);
        @1st @2nd int op_both_arg_rename(in t betterName);
        @1st @2nd int op_both_optionals_difference(in t a);
        @1st int op_both_optionals_difference(in t a, in int b);
        @2nd int op_both_optionals_difference(in t a, in boolean b);
        @1st int op_only_first();
        @2nd int op_only_second();
      };''')

  def test_mergeDartName(self):
    file_name1 = self._create_input('input1.idl', '''
      module M {
        interface I {
          [ImplementationFunction=foo] int member(in int a);
        };
      };''')
    self._builder.import_idl_file(file_name1,
      DatabaseBuilderOptions(source='1st',
        idl_syntax=idlparser.FREMONTCUT_SYNTAX))
    file_name2 = self._create_input('input2.idl', '''
      module M {
        interface I {
          [DartName=bar] int member(in int a);
        };
      };''')
    self._builder.import_idl_file(file_name2,
      DatabaseBuilderOptions(source='2nd',
        idl_syntax=idlparser.FREMONTCUT_SYNTAX))
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      @1st(module=M) @2nd(module=M) interface I {
        /* Operations */
        @1st @2nd [DartName=bar, ImplementationFunction=foo] int member(in int a);
      };''')

  def test_supplemental(self):
    file_name = self._create_input('input1.idl', '''
      module M {
        interface I {
          readonly attribute int a;
        };
        [Supplemental] interface I {
          readonly attribute int b;
        };
      };''')
    self._builder.import_idl_file(file_name,
      DatabaseBuilderOptions(source='Src'))
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      @Src(module=M) [Supplemental] interface I {
        /* Attributes */
        @Src getter attribute int a;
        @Src getter attribute int b;
      };''')

  def test_impl_stmt(self):
    file_name = self._create_input('input.idl', '''
      module M {
        interface I {};
        I implements J;
      };''')
    self._builder.import_idl_file(file_name,
      DatabaseBuilderOptions(source='Src'))
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      @Src(module=M) interface I :
        @Src J {
      };''')

  def test_obsolete(self):
    file_name1 = self._create_input('input1.idl', '''
      module M {
        interface I {
          readonly attribute int keep;
          readonly attribute int obsolete; // Would be removed
        };
      };''')
    self._builder.import_idl_file(file_name1,
      DatabaseBuilderOptions(source='src'))
    file_name2 = self._create_input('input2.idl', '''
      module M {
        interface I {
          readonly attribute int keep;
          readonly attribute int new;
        };
      };''')
    self._builder.import_idl_file(file_name2,
      DatabaseBuilderOptions(source='src',
                   obsolete_old_declarations=True))
    self._builder.merge_imported_interfaces([])
    self._db.Save()
    self._assert_content_equals('I.idl', '''
      @src(module=M) interface I {
        /* Attributes */
        @src getter attribute int keep;
        @src getter attribute int new;
      };''')

  def test_annotation_normalization(self):
    file_name = self._create_input('input.idl', '''
      module M {
        interface I : J{
          const int C = 0;
          readonly attribute int a;
          int op();
        };
      };''')
    self._builder.import_idl_file(file_name,
      DatabaseBuilderOptions(source='Src', source_attributes={'x': 'y'}))
    self._builder.merge_imported_interfaces([])
    interface = self._db.GetInterface('I')
    interface.parents[0].annotations['Src']['x'] = 'u'
    interface.constants[0].annotations['Src']['z'] = 'w'
    interface.attributes[0].annotations['Src']['x'] = 'u'
    self._db.Save()

    # Before normalization
    self._assert_content_equals('I.idl', '''
      @Src(module=M, x=y)
      interface I : @Src(x=u) J {
        /* Constants */
        @Src(x=y, z=w) const int C = 0;
        /* Attributes */
        @Src(x=u) getter attribute int a;
        /* Operations */
        @Src(x=y) int op();
      };''')

    # Normalize
    self._builder.normalize_annotations(['Src'])
    self._db.Save()

    # After normalization
    self._assert_content_equals('I.idl', '''
      @Src(module=M, x=y)
      interface I : @Src(x=u) J {
        /* Constants */
        @Src(z=w) const int C = 0;
        /* Attributes */
        @Src(x=u) getter attribute int a;
        /* Operations */
        @Src int op();
      };''')

  def test_fix_displacements(self):
    file_name1 = self._create_input('input1.idl', '''
      module M {
        interface I {};
        interface J : I {
          readonly attribute int attr;
        };
      };''')
    self._builder.import_idl_file(file_name1,
      DatabaseBuilderOptions(source='1st'))
    file_name2 = self._create_input('input2.idl', '''
      module M {
        interface I {
          readonly attribute int attr;
        };
        interface J : I {};
      };''')
    self._builder.import_idl_file(file_name2,
      DatabaseBuilderOptions(source='2nd'))
    self._builder.merge_imported_interfaces([])
    self._builder.fix_displacements('2nd')
    self._db.Save()
    self._assert_content_equals('J.idl', '''
      @1st(module=M) @2nd(module=M) interface J :
        @1st @2nd I {
        /* Attributes */
        @1st
        @2nd(via=I)
        getter attribute int attr;
      };''')


if __name__ == "__main__":
  logging.config.fileConfig("logging.conf")
  if __name__ == '__main__':
    unittest.main()
