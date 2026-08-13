// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../code_fragment_parser_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingTokenTest);
  });
}

@reflectiveTest
class MissingTokenTest extends AbstractCodeFragmentParserTest {
  void test_closeBracket() {
    assertErrors('arguments[2', [error(diag.missingToken, 10, 1)]);
  }

  void test_empty() {
    assertErrors('', [error(diag.missingToken, 0, 0)]);
  }

  void test_identifier_afterPeriod() {
    assertErrors('arguments[2].', [error(diag.missingToken, 12, 1)]);
  }

  void test_identifier_initial() {
    assertErrors('', [error(diag.missingToken, 0, 0)]);
  }

  void test_index() {
    assertErrors('arguments[', [error(diag.missingToken, 9, 1)]);
  }

  void test_openBracket() {
    assertErrors('arguments', [error(diag.missingToken, 0, 9)]);
  }
}
