// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidShadowingTypeParametersTest);
  });
}

@reflectiveTest
class AvoidShadowingTypeParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_shadowing_type_parameters';

  test_enum() async {
    await assertDiagnostics(r'''
enum E<T> {
  a, b, c;
  void fn<T>() {}
}
''', [
      lint(33, 1),
    ]);
  }

  test_extensionType() async {
    await assertDiagnostics(r'''
extension type E<T>(int i) {
  void m<T>() {}
}
''', [
      lint(38, 1),
    ]);
  }

  test_wrongNumberOfTypeArguments() async {
    await assertDiagnostics(r'''
typedef Predicate = bool <E>(E element);
''', [
      // No lint.
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 20, 8),
      error(CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT, 26, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 28, 1),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 29, 1),
    ]);
  }
}
