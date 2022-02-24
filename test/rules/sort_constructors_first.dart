// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortConstructorsFirstTest);
  });
}

@reflectiveTest
class SortConstructorsFirstTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'sort_constructors_first';

  test_ok() async {
    await assertNoDiagnostics(r'''
enum A {
  a,b,c;
  const A();
  int f() => 0;
}
''');
  }

  test_unsorted() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int f() => 0;
  const A();
}
''', [
      lint('sort_constructors_first', 42, 1),
    ]);
  }
}
