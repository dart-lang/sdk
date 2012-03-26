#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Tests for dartgenerator."""

import logging.config
import os.path
import re
import shutil
import tempfile
import unittest
import dartgenerator
import database
import idlnode
import idlparser


class DartGeneratorTestCase(unittest.TestCase):

  def _InDatabase(self, interface_name):
    return os.path.exists(os.path.join(self._database_dir,
                                       '%s.idl' % interface_name))

  def _FilePathForDartInterface(self, interface_name):
    return os.path.join(self._generator._output_dir, 'src', 'interface',
                        '%s.dart' % interface_name)

  def _InOutput(self, interface_name):
    return os.path.exists(
        self._FilePathForDartInterface(interface_name))

  def _ReadOutputFile(self, interface_name):
    self.assertTrue(self._InOutput(interface_name))
    file_path = self._FilePathForDartInterface(interface_name)
    f = open(file_path, 'r')
    content = f.read()
    f.close()
    return content, file_path

  def _AssertOutputSansHeaderEquals(self, interface_name, expected_content):
    full_actual_content, file_path = self._ReadOutputFile(interface_name)
    # Remove file header comments in // or multiline /* ... */ syntax.
    header_re = re.compile(r'^(\s*(//.*|/\*([^*]|\*[^/])*\*/)\s*)*')
    actual_content = header_re.sub('', full_actual_content)
    if expected_content != actual_content:
      msg = """
FILE: %s
EXPECTED:
%s
ACTUAL:
%s
""" % (file_path, expected_content, actual_content)
      self.fail(msg)

  def _AssertOutputContains(self, interface_name, expected_content):
    actual_content, file_path = self._ReadOutputFile(interface_name)
    if expected_content not in actual_content:
      msg = """
STRING: %s
Was found not in output file: %s
FILE CONTENT:
%s
""" % (expected_content, file_path, actual_content)
      self.fail(msg)

  def _AssertOutputDoesNotContain(self, interface_name, expected_content):
    actual_content, file_path = self._ReadOutputFile(interface_name)
    if expected_content in actual_content:
      msg = """
STRING: %s
Was found in output file: %s
FILE CONTENT:
%s
""" % (expected_content, file_path, actual_content)
      self.fail(msg)

  def setUp(self):
    self._working_dir = tempfile.mkdtemp()
    self._output_dir = os.path.join(self._working_dir, 'output')
    self._database_dir = os.path.join(self._working_dir, 'database')
    self._auxiliary_dir = os.path.join(self._working_dir, 'auxiliary')
    self.assertFalse(os.path.exists(self._database_dir))

    # Create database and add one interface.
    db = database.Database(self._database_dir)
    os.mkdir(self._auxiliary_dir)
    self.assertTrue(os.path.exists(self._database_dir))

    content = """
    module shapes {
      @A1 @A2
      interface Shape {
        @A1 @A2 getter attribute int attr;
        @A1 setter attribute int attr;
        @A3 boolean op();
        const long CONSTANT = 1;
        getter attribute DOMString strAttr;
        Shape create();
        boolean compare(Shape s);
        Rectangle createRectangle();
        void addLine(lines::Line line);
        void someDartType(File file);
        void someUnidentifiedType(UnidentifiableType t);
      };
    };

    module rectangles {
      @A3
      interface Rectangle : @A3 shapes::Shape {
        void someTemplatedType(List<Shape> list);
      };
    };

    module lines {
      @A1
      interface Line : shapes::Shape {
      };
    };
    """

    parser = idlparser.IDLParser(idlparser.FREMONTCUT_SYNTAX)
    ast = parser.parse(content)
    idl_file = idlnode.IDLFile(ast)
    for module in idl_file.modules:
      module_name = module.id
      for interface in module.interfaces:
        db.AddInterface(interface)
    db.Save()

    self.assertTrue(self._InDatabase('Shape'))
    self.assertTrue(self._InDatabase('Rectangle'))
    self.assertTrue(self._InDatabase('Line'))

    self._database = database.Database(self._database_dir)
    self._generator = dartgenerator.DartGenerator(self._auxiliary_dir,
                                                  '../templates',
                                                  'test')

  def tearDown(self):
    shutil.rmtree(self._database_dir)
    shutil.rmtree(self._auxiliary_dir)

  def testBasicGeneration(self):
    # Generate all interfaces:
    self._database.Load()
    self._generator.Generate(self._database, self._output_dir)
    self._generator.Flush()

    self.assertTrue(self._InOutput('Shape'))
    self.assertTrue(self._InOutput('Rectangle'))
    self.assertTrue(self._InOutput('Line'))

  def testFilterByAnnotations(self):
    self._database.Load()
    self._generator.FilterInterfaces(self._database, ['A1', 'A2'], ['A3'])
    self._generator.Generate(self._database, self._output_dir)
    self._generator.Flush()

    # Only interfaces with (@A1 and @A2) or @A3 should be generated:
    self.assertTrue(self._InOutput('Shape'))
    self.assertTrue(self._InOutput('Rectangle'))
    self.assertFalse(self._InOutput('Line'))

    # Only members with (@A1 and @A2) or @A3 should be generated:
    # TODO(sra): make th
    self._AssertOutputSansHeaderEquals('Shape', """interface Shape {

  final int attr;

  bool op();
}
""")

    self._AssertOutputContains('Rectangle',
                               'interface Rectangle extends shapes::Shape')

  def testTypeRenames(self):
    self._database.Load()
    # Translate 'Shape' to spanish:
    self._generator.RenameTypes(self._database, {'Shape': 'Forma'}, False)
    self._generator.Generate(self._database, self._output_dir)
    self._generator.Flush()

    # Validate that all references to Shape have been converted:
    self._AssertOutputContains('Forma',
                               'interface Forma')
    self._AssertOutputContains('Forma', 'Forma create();')
    self._AssertOutputContains('Forma',
                               'bool compare(Forma s);')
    self._AssertOutputContains('Rectangle',
                               'interface Rectangle extends Forma')

  def testQualifiedDartTypes(self):
    self._database.Load()
    self._generator.FilterMembersWithUnidentifiedTypes(self._database)
    self._generator.Generate(self._database, self._output_dir)
    self._generator.Flush()

    # Verify primitive conversions are working:
    self._AssertOutputContains('Shape',
                               'static final int CONSTANT = 1')
    self._AssertOutputContains('Shape',
                               'final String strAttr;')

    # Verify interface names are converted:
    self._AssertOutputContains('Shape',
                               'interface Shape {')
    self._AssertOutputContains('Shape',
                               ' Shape create();')
    # TODO(sra): Why is this broken? Output contains qualified type.
    #self._AssertOutputContains('Shape',
    #                           'void addLine(Line line);')
    self._AssertOutputContains('Shape',
                               'Rectangle createRectangle();')
    # TODO(sra): Why is this broken? Output contains qualified type.
    #self._AssertOutputContains('Rectangle',
    #                           'interface Rectangle extends Shape')
    # Verify dart names are preserved:
    # TODO(vsm): Re-enable when package / namespaces are enabled.
    # self._AssertOutputContains('shapes', 'Shape',
    #   'void someDartType(File file);')

    # Verify that unidentified types are not removed:
    self._AssertOutputDoesNotContain('Shape',
                                     'someUnidentifiedType')

    # Verify template conversion:
    # TODO(vsm): Re-enable when core collections are supported.
    # self._AssertOutputContains('rectangles', 'Rectangle',
    #  'void someTemplatedType(List<Shape> list)')


if __name__ == '__main__':
  logging.config.fileConfig('logging.conf')
  if __name__ == '__main__':
    unittest.main()
