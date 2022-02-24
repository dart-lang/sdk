// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryGettersSettersTest);
  });
}

@reflectiveTest
class UnnecessaryGettersSettersTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'unnecessary_getters_setters';

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  var _contents;
  get contents => _contents;
  set contents(value) {
    _contents = value;
  }
}
''', [
      lint('unnecessary_getters_setters', 41, 8),
    ]);
  }
}
