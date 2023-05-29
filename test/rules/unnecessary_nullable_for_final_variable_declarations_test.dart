// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullableForFinalVariableDeclarationsTest);
  });
}

@reflectiveTest
class UnnecessaryNullableForFinalVariableDeclarationsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_nullable_for_final_variable_declarations';

  test_list() async {
    await assertDiagnostics(r'''
f() {
  final [int a, num? c] = [0, 1];
  print('$a$c');
}
''', [
      lint(22, 6),
    ]);
  }

  test_list_dynamic_ok() async {
    await assertNoDiagnostics(r'''
f() {
  final [dynamic a, num c] = [0, 1];
  print('$a$c');
}
''');
  }

  test_record() async {
    await assertDiagnostics(r'''
f() {
  final (List<int>? a, num? c) = ([], 1);
  print('$a$c');
}
''', [
      lint(15, 12),
      lint(29, 6),
    ]);
  }
}
