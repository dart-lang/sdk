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

  test_field() async {
    await assertDiagnostics(r'''    
enum A {
  a,b,c;
  @override
  Type get runtimeType => super.runtimeType;
}
''', [
      lint('unnecessary_overrides', 41, 11),
    ]);
  }

  test_method() async {
    await assertDiagnostics(r'''    
enum A {
  a,b,c;
  @override
  String toString() => super.toString();
}
''', [
      lint('unnecessary_overrides', 39, 8),
    ]);
  }
}
