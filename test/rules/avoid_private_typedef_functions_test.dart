// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  String get lintRule => 'avoid_private_typedef_functions';

  test_nonFunctionTypeAlias() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
typedef _Td = List<String>;
''');
  }

  /// https://github.com/dart-lang/linter/issues/4665
  test_nonFunctionTypeAlias_record() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
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
    var lib = newFile('$testPackageLibPath/lib.dart', r'''
part 'test.dart';
typedef _Td = void Function();
''');
    addTestFile(r'''
part of 'lib.dart';
late _Td td1;
late _Td td2;
''');
    await resolveTestFile();
    var partResult = await resolveFile(lib.path);
    await assertNoDiagnosticsIn(partResult.errors);
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
    var lib = newFile('$testPackageLibPath/lib.dart', r'''
part 'test.dart';
typedef _Td = void Function();
''');
    addTestFile(r'''
part of 'lib.dart';
late _Td td;
''');
    await resolveTestFile();
    var partResult = await resolveFile(lib.path);
    await assertDiagnosticsIn(partResult.errors, [
      lint(26, 3),
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
// ignore: unused_element
typedef _Td = int Function();
''', [
      lint(34, 3),
    ]);
  }

  test_private_legacyTypeAlias_usedZeroTimes() async {
    await assertDiagnostics(r'''
// ignore: unused_element
typedef int _Td();
''', [
      lint(38, 3),
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
