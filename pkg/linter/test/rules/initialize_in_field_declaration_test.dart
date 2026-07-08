// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializeInFieldDeclarationTest);
  });
}

@reflectiveTest
class InitializeInFieldDeclarationTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.initialize_in_field_declaration;

  test_class_doesNotReferenceParameter() async {
    await assertNoDiagnostics(r'''
class C(int x) {
  this : y = 0;

  int y;
}
''');
  }

  test_class_lateField() async {
    await assertNoDiagnostics(r'''
class C(int x) {
  this : y = x;

  late int y;
}
''');
  }

  test_class_multipleInitializers() async {
    await assertDiagnosticsFromMarkup(r'''
class C(int x, int z) {
  this : [!y!] = x, w = 0;

  int y;
  int w;
}
''');
  }

  test_class_onDifferentLines() async {
    await assertDiagnosticsFromMarkup(r'''
class C(int x) {
  this : [!y!] = x;

  int y;
}
''');
  }
}
