// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryDevDependencyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryDevDependencyTest extends PubspecDiagnosticTest {
  test_unnecessaryDevDependency_error() {
    assertDiagnostics('''
name: sample
dependencies:
  a: any
dev_dependencies:
  a: any
//^
// [diag.unnecessaryDevDependency] The dev dependency on a is unnecessary because there is also a normal dependency on that package.
''');
  }

  test_unnecessaryDevDependency_error_null() {
    assertDiagnostics('''
name: sample
dependencies:
  null: any
dev_dependencies:
  null: any
//^^^^
// [diag.unnecessaryDevDependency] The dev dependency on null is unnecessary because there is also a normal dependency on that package.
''');
  }

  test_unnecessaryDevDependency_noError() {
    assertDiagnostics('''
name: sample
dependencies:
  a: any
dev_dependencies:
  b: any
''');
  }
}
