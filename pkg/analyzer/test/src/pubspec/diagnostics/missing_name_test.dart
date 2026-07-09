// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingNameTest extends PubspecDiagnosticTest {
  test_missingName_error() {
    assertDiagnostics(
      '''

// [diag.missingName][column 1][length 0] The 'name' field is required but missing.''',
    );
  }

  test_missingName_noError() {
    assertDiagnostics('''
name: sample
''');
  }
}
