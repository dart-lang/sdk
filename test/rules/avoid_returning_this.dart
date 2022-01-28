// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidReturningThisTest);
  });
}

@reflectiveTest
class AvoidReturningThisTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'avoid_returning_this';

  test_method() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  A a() => this;
}
''', [
      lint('avoid_returning_this', 22, 1),
    ]);
  }
}
