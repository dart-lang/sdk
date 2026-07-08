// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DependenciesFieldNotMapTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DependenciesFieldNotMapTest extends PubspecDiagnosticTest {
  test_dependenciesField_empty() {
    assertDiagnostics('''
name: sample
dependencies:
''');
  }

  test_dependenciesFieldNotMap_error_bool() {
    assertDiagnostics('''
name: sample
dependencies: true
//            ^^^^
// [diag.dependenciesFieldNotMap] The value of the 'dependencies' field is expected to be a map.
''');
  }

  test_dependenciesFieldNotMap_noError() {
    assertDiagnostics('''
name: sample
dependencies:
  a: any
''');
  }

  test_devDependenciesFieldNotMap_dev_error_bool() {
    assertDiagnostics('''
name: sample
dev_dependencies: true
//                ^^^^
// [diag.dependenciesFieldNotMap] The value of the 'dev_dependencies' field is expected to be a map.
''');
  }
}
