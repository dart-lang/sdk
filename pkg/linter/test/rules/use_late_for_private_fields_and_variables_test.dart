// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseLateForPrivateFieldsAndVariablesTest);
  });
}

@reflectiveTest
class UseLateForPrivateFieldsAndVariablesTest extends LintRuleTest {
  @override
  String get lintRule => 'use_late_for_private_fields_and_variables';

  test_extensionType_instanceField() async {
    await assertDiagnostics('''
extension type E(int i) {
  int? _i;
}
''', [
      // No lint.
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD, 33, 2),
      error(WarningCode.UNUSED_FIELD, 33, 2),
    ]);
  }

  test_extensionType_staticField() async {
    await assertDiagnostics('''
extension type E(int i) {
  static int? _i;
}
''', [
      error(WarningCode.UNUSED_FIELD, 40, 2),
      lint(40, 2),
    ]);
  }

  test_instanceField_private() async {
    await assertDiagnostics('''
class C {
  int? _i; // ignore: unused_field
}
''', [lint(17, 2)]);
  }

  /// https://github.com/dart-lang/linter/issues/3823
  test_instanceField_private_enum() async {
    await assertDiagnostics('''
enum E {
  a('a'),
  b('b', 'c');

  const E(this._v, [this._v2]);

  final String _v;
  final String? _v2;
}
''', [
      // No lint.
      error(WarningCode.UNUSED_FIELD, 83, 2),
      error(WarningCode.UNUSED_FIELD, 103, 3),
    ]);
  }

  test_instanceField_private_inClassWithConstConstructor() async {
    await assertNoDiagnostics('''
class C {
  const C([this._i]);
  final int? _i; // ignore: unused_field
}
''');
  }

  test_instanceField_private_inEnum() async {
    await assertNoDiagnostics('''
enum E {
  a('');
  const E([this._f]);
  final String? _f; // ignore: unused_field
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/2921')
  test_instanceField_private_partOf() async {
    newFile('$testPackageLibPath/part.dart', r'''
part 'test.dart';

class C {
  final String? _s;
  C(this._s);
}
''');
    await assertNoDiagnostics('''
part of 'part.dart';
''');
  }

  test_instanceField_public() async {
    await assertNoDiagnostics('''
class C {
  int? i;
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4180
  test_patternAssignment_field() async {
    await assertDiagnostics('''
class C {
  int? _i;
  void m() {
    _i?.abs();
    (_i, ) = (null, );
  }
}
''', [
      // No lint.
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 54, 2),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4180
  test_patternAssignment_topLevel() async {
    await assertDiagnostics('''
int? _i;
m() {
  _i?.abs();
  (_i, ) = (null, );
}
''', [
      // No lint.
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 31, 2),
    ]);
  }

  test_staticField_private_onExtension() async {
    await assertDiagnostics('''
extension E on int {
  static int? _i; // ignore: unused_field
}
''', [lint(35, 2)]);
  }

  // TODO(srawlins): Add test_staticField_private_onClass.

  test_staticField_public_onPrivateExtension() async {
    await assertDiagnostics('''
extension _E on int {
  static int? i; // ignore: unused_field
}
''', [lint(36, 1)]);
  }

  test_staticField_public_onPublicExtension() async {
    await assertNoDiagnostics('''
extension E on int {
  static int? i;
}
''');
  }

  test_staticField_public_onUnnamedExtension() async {
    await assertDiagnostics('''
extension on int {
  static int? i; // ignore: unused_field
}
''', [lint(33, 1)]);
  }

  test_topLevel_assigned() async {
    await assertDiagnostics('''
int? _i; // ignore: unused_element
void f() {
  _i = 1;
}
''', [lint(5, 2)]);
  }

  test_topLevel_neverUsed() async {
    await assertDiagnostics('''
int? _i; // ignore: unused_element
''', [lint(5, 2)]);
  }

  test_topLevel_onlyAssignedNull() async {
    await assertNoDiagnostics('''
int? _i; // ignore: unused_element
void f() {
  _i = null;
}
''');
  }

  test_topLevel_onlyEqualityCompared() async {
    await assertNoDiagnostics('''
int? _i; // ignore: unused_element
f() {
  _i == 1;
}
''');
  }

  test_topLevel_onlyNullAwareAccess() async {
    await assertNoDiagnostics('''
int? _i; // ignore: unused_element
f() {
  _i?.abs();
}
''');
  }

  test_topLevel_onlyNullChecked() async {
    await assertDiagnostics('''
int? _i; // ignore: unused_element
f() {
  _i!.abs();
}
''', [lint(5, 2)]);
  }

  test_topLevel_onlyNullChecked_beforePassedAsArgument() async {
    await assertDiagnostics('''
int? _i; // ignore: unused_element
f(int i) {
  f(_i!);
}
''', [lint(5, 2)]);
  }

  test_topLevel_onlyNullTest() async {
    await assertNoDiagnostics('''
int? _i; // ignore: unused_element
f() {
  if (_i != null) _i.toString();
}
''');
  }

  test_topLevel_passedAsArgument() async {
    await assertNoDiagnostics('''
int? _i;
f(int? i) {
  f(_i);
}
''');
  }

  test_topLevel_public() async {
    await assertNoDiagnostics('''
int? i;
void f() {
  i = 1;
}
''');
  }

  test_useInPart() async {
    newFile2('$testPackageRootPath/lib/lib.dart', '''
part '$testFileName';

int? _i;
''');
    await assertDiagnostics('''
part of 'lib.dart';

m() {
  _i = 1;
}
''', [lint(24, 2)]);
  }
}
