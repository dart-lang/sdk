// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Conventions for tests written using `package:test_reflective_loader` aren't
// compatible with the `non_constant_identifier_names` lint.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_utilities/extensions/string.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringExtensionTest);
  });
}

@reflectiveTest
class StringExtensionTest {
  void test_toCamelCase() {
    expect('CAMEL_CASE'.toCamelCase(), 'camelCase');
    expect('alreadyCamel_case'.toCamelCase(), 'alreadycamelCase');
    expect('FOO_123_BAR'.toCamelCase(), 'foo123Bar');
    expect('FOO'.toCamelCase(), 'foo');
    expect('___'.toCamelCase(), '___');
    expect(''.toCamelCase(), '');
    expect('_FOO_BAR'.toCamelCase(), '_fooBar');
    expect('FOO__BAR'.toCamelCase(), 'fooBar');
    expect('FOO_BAR_'.toCamelCase(), 'fooBar');
  }

  void test_toPascalCase() {
    expect('PASCAL_CASE'.toPascalCase(), 'PascalCase');
    expect('AlreadyPascal_case'.toPascalCase(), 'AlreadypascalCase');
    expect('FOO_123_BAR'.toPascalCase(), 'Foo123Bar');
    expect('FOO'.toPascalCase(), 'Foo');
    expect('___'.toPascalCase(), '___');
    expect(''.toPascalCase(), '');
    expect('_FOO_BAR'.toPascalCase(), '_FooBar');
    expect('FOO__BAR'.toPascalCase(), 'FooBar');
    expect('FOO_BAR_'.toPascalCase(), 'FooBar');
  }
}
