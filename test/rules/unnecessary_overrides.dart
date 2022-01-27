// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryOverridesTest);
  });
}

@reflectiveTest
class UnnecessaryOverridesTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'unnecessary_overrides';

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3097')
  test_field() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  int get foo => 0;
}
''', [
      lint('unnecessary_overrides', 28, 8),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3097')
  test_method() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  String bar() => '';
}
''', [
      lint('unnecessary_overrides', 27, 8),
    ]);
  }
}
