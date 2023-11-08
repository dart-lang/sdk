// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestTypesInEqualsTest);
  });
}

@reflectiveTest
class TestTypesInEqualsTest extends LintRuleTest {
  @override
  String get lintRule => 'test_types_in_equals';

  test_doesNotUseIs() async {
    await assertDiagnostics(r'''
class C {
  int? x;

  @override
  bool operator ==(Object other) {
    C otherC = other as C;
    return otherC.x == x;
  }
}
''', [
      lint(83, 10),
    ]);
  }

  test_usesIs() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is C && this.x == other.x;
  }
}
''');
  }
}
