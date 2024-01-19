// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidClassesWithOnlyStaticMembers);
  });
}

@reflectiveTest
class AvoidClassesWithOnlyStaticMembers extends LintRuleTest {
  @override
  String get lintRule => 'avoid_classes_with_only_static_members';

  test_basicClass() async {
    await assertDiagnostics(r'''
class C {
  static void f() {}
}
''', [
      lint(0, 32),
    ]);
  }

  test_finalClass() async {
    await assertDiagnostics(r'''
final class C {
  static void f() {}
}
''', [
      lint(0, 38),
    ]);
  }

  test_sealedClass() async {
    await assertNoDiagnostics(r'''
sealed class C {
  static void f() {}
}
''');
  }
}
