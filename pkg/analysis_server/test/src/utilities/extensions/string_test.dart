// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ToFileNameTest);
    defineReflectiveTests(ToLowerCamelCaseTest);
  });
}

@reflectiveTest
class ToFileNameTest {
  void test_multiple() {
    expect('MyFooClass'.toFileName, 'my_foo_class.dart');
  }

  void test_single() {
    expect('Class'.toFileName, 'class.dart');
  }
}

@reflectiveTest
class ToLowerCamelCaseTest {
  void test_adjacentUnderscores() {
    expect('a__b'.toLowerCamelCase, null);
  }

  void test_empty() {
    expect(''.toLowerCamelCase, null);
  }

  void test_leadingUnderscore() {
    expect('_a'.toLowerCamelCase, null);
  }

  void test_screamingCaps() {
    expect('AA_BB'.toLowerCamelCase, 'aaBb');
  }

  void test_snakeCase() {
    expect('aa_bb'.toLowerCamelCase, 'aaBb');
  }

  void test_trailingUnderscore() {
    expect('a_'.toLowerCamelCase, null);
  }
}
