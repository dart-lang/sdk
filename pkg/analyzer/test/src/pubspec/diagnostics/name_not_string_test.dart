// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NameNotStringTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NameNotStringTest extends PubspecDiagnosticTest {
  test_nameNotString_error_int() {
    assertDiagnostics('''
name: 42
//    ^^
// [diag.nameNotString] The value of the 'name' field is required to be a string.
''');
  }

  test_nameNotString_noError() {
    assertDiagnostics('''
name: sample
''');
  }
}
