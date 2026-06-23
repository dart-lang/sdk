// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryLateTest);
  });
}

@reflectiveTest
class UnnecessaryLateTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_late;

  test_local_initializer() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    late String a = '';
  }
}
''');
  }

  test_multipleVariables_eachHasInitializer() async {
    await assertDiagnosticsFromMarkup(r'''
[!late!] String a = '',
    b = '';
''');
  }

  test_multipleVariables_oneHasInitializer_oneHasNoInitializer() async {
    await assertNoDiagnostics(r'''
late String a, b = '';
''');
  }

  test_static_initializer() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  static [!late!] String a = '';
}
''');
  }

  test_static_noInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  static late String a;
}
''');
  }

  test_static_nonLate() async {
    await assertNoDiagnostics(r'''
class C {
  static String a = '';
}
''');
  }

  test_topLevel_initializer() async {
    await assertDiagnosticsFromMarkup(r'''
[!late!] String a = '';
''');
  }

  test_topLevel_noInitializer() async {
    await assertNoDiagnostics(r'''
late String a;
''');
  }

  test_topLevel_noLate() async {
    await assertNoDiagnostics(r'''
String a = '';
''');
  }
}
