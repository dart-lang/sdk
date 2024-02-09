// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EraseDartTypeExtensionTypesTest);
  });
}

@reflectiveTest
class EraseDartTypeExtensionTypesTest extends LintRuleTest {
  @override
  bool get addKernelPackageDep => true;

  @override
  String get lintRule => 'erase_dart_type_extension_types';

  test_isDartType() async {
    await assertDiagnostics(r'''
import 'package:kernel/ast.dart';

void f(Object t) {
  t is DartType;
}
''', [
      lint(56, 13),
    ]);
  }

  test_isDartType_subclass() async {
    await assertDiagnostics(r'''
import 'package:kernel/ast.dart';

void f(Object t) {
  t is InterfaceType;
}
''', [
      lint(56, 18),
    ]);
  }
}
