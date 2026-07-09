// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Conventions for tests written using `package:test_reflective_loader` aren't
// compatible with the `non_constant_identifier_names` lint.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/utilities/extensions/string.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringExtensionTest);
  });
}

@reflectiveTest
class StringExtensionTest {
  void test_isCamelCase() {
    expect('UPPER_CASE_WITH_UNDERSCORES'.isCamelCase, false);
    expect('lower_case_with_underscores'.isCamelCase, false);
    expect('camelCase'.isCamelCase, true);
    expect('PascalCase'.isCamelCase, false);
    expect('alllowercase'.isCamelCase, true);
    expect('ALLUPPERCASE'.isCamelCase, false);
    expect('foo123Bar'.isCamelCase, true);
    expect('Foo123Bar'.isCamelCase, false);
    expect('123'.isCamelCase, false);
  }

  void test_isPascalCase() {
    expect('UPPER_CASE_WITH_UNDERSCORES'.isPascalCase, false);
    expect('lower_case_with_underscores'.isPascalCase, false);
    expect('camelCase'.isPascalCase, false);
    expect('PascalCase'.isPascalCase, true);
    expect('alllowercase'.isPascalCase, false);
    expect('ALLUPPERCASE'.isPascalCase, true);
    expect('foo123Bar'.isPascalCase, false);
    expect('Foo123Bar'.isPascalCase, true);
    expect('123'.isPascalCase, false);
  }

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

  void test_toSnakeCase() {
    expect('camelCase'.toSnakeCase(), 'camel_case');
    expect('PascalCase'.toSnakeCase(), 'pascal_case');
    expect('already_snake_case'.toSnakeCase(), 'already_snake_case');
    expect(
      'mixedCamel_AndPascal_and_snake'.toSnakeCase(),
      'mixed_camel_and_pascal_and_snake',
    );
    expect('with123Numbers'.toSnakeCase(), 'with123_numbers');
    expect(''.toSnakeCase(), '');
    expect(
      'CONSECUTIVE_UPCASE'.toSnakeCase(),
      'c_o_n_s_e_c_u_t_i_v_e_u_p_c_a_s_e',
    );
  }
}
