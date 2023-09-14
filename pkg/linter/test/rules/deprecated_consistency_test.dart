// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedConsistencyTest);
  });
}

@reflectiveTest
class DeprecatedConsistencyTest extends LintRuleTest {
  @override
  String get lintRule => 'deprecated_consistency';

  test_superInit() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  A({@deprecated this.a});
}

class B extends A {
  B({super.a});
}
''', [
      lint(20, 1),
    ]);
  }
}
