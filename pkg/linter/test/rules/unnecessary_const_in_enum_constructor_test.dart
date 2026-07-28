// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryConstInEnumConstructorTest);
  });
}

@reflectiveTest
class UnnecessaryConstInEnumConstructorTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_const_in_enum_constructor;

  test_inBody_inClass() async {
    await assertNoDiagnostics(r'''
class C {
  const C();
}
''');
  }

  test_inBody_inEnum() async {
    await assertDiagnosticsFromMarkup(r'''
enum E {
  a(1), b(2);

  [!const!] E(this.i);

  final int i;
}
''');
  }

  test_primary_inClass() async {
    await assertNoDiagnostics(r'''
class const C();
''');
  }

  test_primary_inEnum() async {
    await assertDiagnosticsFromMarkup(r'''
enum [!const!] E(final int i) {
  a(1), b(2);
}
''');
  }
}
