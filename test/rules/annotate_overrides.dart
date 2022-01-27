// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotateOverridesTest);
  });
}

@reflectiveTest
class AnnotateOverridesTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'annotate_overrides';

  test_field() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int get hashCode => 0;
}
''', [
      lint('annotate_overrides', 28, 8),
    ]);
  }

  test_method() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  String toString() => '';
}
''', [
      lint('annotate_overrides', 27, 8),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3093')
  test_ok() async {
    await assertNoDiagnostics(r'''
enum A {
  a,b,c;
  @override
  int get hashCode => 0;
  @override
  String toString() => '';
}
''');
  }
}
