// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypeToStringTest);
  });
}

@reflectiveTest
class AvoidTypeToStringTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_type_to_string';

  test_extensionType_implicitThis() async {
    await assertDiagnostics(r'''
extension type E(int i) {
  m() {
    runtimeType.toString();
  }
}
''', [
      lint(50, 8),
    ]);
  }

  test_extensionType_instance() async {
    await assertDiagnostics(r'''
extension type E(int i) {
  m() {
    E(i).runtimeType.toString();
  }
}
''', [
      lint(55, 8),
    ]);
  }
}
