// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../code_fragment_parser_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCharacterTest);
  });
}

@reflectiveTest
class InvalidCharacterTest extends AbstractCodeFragmentParserTest {
  void test_final() {
    assertErrors('arguments;', [error(diag.invalidCharacter, 9, 1)]);
  }

  void test_initial() {
    assertErrors('{ some', [error(diag.invalidCharacter, 0, 1)]);
  }
}
