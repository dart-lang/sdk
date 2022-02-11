// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OmitLocalVariableTypesTest);
  });
}

@reflectiveTest
class OmitLocalVariableTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'omit_local_variable_types';

  /// https://github.com/dart-lang/linter/issues/3016
  @failingTest
  test_paramIsType() async {
    await assertDiagnostics(r'''
T bar<T>(T d) => d;

String f() {
  String h = bar('');
  return h;
}
''', [
      lint('omit_local_variable_types', 42, 26),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3016
  test_typeNeededForInference() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;

String f() {
  String h = bar('');
  return h;
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3016
  test_typeParamProvided() async {
    await assertDiagnostics(r'''
T bar<T>(dynamic d) => d;

String f() {
  String h = bar<String>('');
  return h;
}
''', [
      lint('omit_local_variable_types', 42, 26),
    ]);
  }
}
