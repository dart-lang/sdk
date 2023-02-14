// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantIdentifierNamesRecordsTest);
    defineReflectiveTests(ConstantIdentifierNamesPatternsTest);
  });
}

@reflectiveTest
class ConstantIdentifierNamesPatternsTest extends LintRuleTest {
  @override
  List<String> get experiments => ['patterns', 'records'];

  @override
  String get lintRule => 'constant_identifier_names';

  test_destructuredConstField() async {
    await assertDiagnostics(r'''
class A {
  static const AA = (1, );
}
''', [
      lint(25, 2),
    ]);
  }

  test_destructuredConstVariable() async {
    await assertDiagnostics(r'''
const AA = (1, );
''', [
      lint(6, 2),
    ]);
  }

  test_destructuredFinalVariable() async {
    await assertDiagnostics(r'''
void f() {
  final (AA, ) = (1, );
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 20, 2),
      lint(20, 2),
    ]);
  }
}

@reflectiveTest
class ConstantIdentifierNamesRecordsTest extends LintRuleTest {
  @override
  List<String> get experiments => ['records'];

  @override
  String get lintRule => 'constant_identifier_names';

  test_recordTypeDeclarations() async {
    await assertDiagnostics(r'''
const RR = (x: 1);
''', [
      lint(6, 2),
    ]);
  }

  test_recordTypeDeclarations_ok() async {
    await assertNoDiagnostics(r'''
const r = (x: 1);
''');
  }
}
