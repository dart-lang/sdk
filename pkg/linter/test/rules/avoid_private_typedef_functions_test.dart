// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPrivateTypedefFunctionsTest);
  });
}

@reflectiveTest
class AvoidPrivateTypedefFunctionsTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
        WarningCode.UNUSED_LOCAL_VARIABLE,
      ];

  @override
  String get lintRule => LintNames.avoid_private_typedef_functions;

  test_nonFunctionTypeAlias() async {
    await assertNoDiagnostics(r'''
typedef _Td = List<String>;
''');
  }

  /// https://github.com/dart-lang/linter/issues/4665
  test_nonFunctionTypeAlias_record() async {
    await assertNoDiagnostics(r'''
typedef _Record = (int a, int b);
''');
  }

  test_private_genericFunctionTypeAlias_usedMultipleTimes() async {
    await assertNoDiagnostics(r'''
typedef _Td = int Function();
late _Td td1;
late _Td td2;
''');
  }

  test_private_genericFunctionTypeAlias_usedMultipleTimes_declaredInPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
part 'test.dart';
late _Td td1;
late _Td td2;
''');
    await assertNoDiagnostics(r'''
part of 'lib.dart';
typedef _Td = void Function();
''');
  }

  test_private_genericFunctionTypeAlias_usedMultipleTimes_usedInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';
late _Td td1;
late _Td td2;
''');
    await assertNoDiagnostics(r'''
part 'part.dart';
typedef _Td = void Function();
''');
  }

  test_private_genericFunctionTypeAlias_usedOneTime() async {
    await assertDiagnostics(r'''
typedef _Td = int Function();
late _Td td;
''', [
      lint(8, 3),
    ]);
  }

  test_private_genericFunctionTypeAlias_usedOneTime_declaredInPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
part 'test.dart';
late _Td td;
''');
    await assertDiagnostics(r'''
part of 'lib.dart';
typedef _Td = void Function();
''', [
      lint(28, 3),
    ]);
  }

  test_private_genericFunctionTypeAlias_usedOneTime_usedInPart() async {
    newFile('$testPackageLibPath/part.dart', r'''
part of 'test.dart';
late _Td td;
''');
    await assertDiagnostics(r'''
part 'part.dart';
typedef _Td = void Function();
''', [
      lint(26, 3),
    ]);
  }

  test_private_genericFunctionTypeAlias_usedZeroTimes() async {
    await assertDiagnostics(r'''
typedef _Td = int Function();
''', [
      lint(8, 3),
    ]);
  }

  test_private_legacyTypeAlias_usedZeroTimes() async {
    await assertDiagnostics(r'''
typedef int _Td();
''', [
      lint(12, 3),
    ]);
  }

  test_public_genericFunctionTypeAlias_usedZeroTimes() async {
    await assertNoDiagnostics(r'''
typedef Td = int Function();
''');
  }

  test_public_legacyTypeAlias_usedZeroTimes() async {
    await assertNoDiagnostics(r'''
typedef int Td();
''');
  }
}
