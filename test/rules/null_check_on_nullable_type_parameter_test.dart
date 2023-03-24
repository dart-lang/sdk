// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullCheckOnNullableTypeParameterTestLanguage300);
  });
}

@reflectiveTest
class NullCheckOnNullableTypeParameterTestLanguage300 extends LintRuleTest
    with LanguageVersion300Mixin {
  @override
  String get lintRule => 'null_check_on_nullable_type_parameter';

  test_nullAssertPattern() async {
    await assertDiagnostics(r'''
void f<T>((T?, T?) p){
  var (x!, y) = p;
}
''', [
      lint(31, 1),
    ]);
  }
}
