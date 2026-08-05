// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullComparisonFalseTest);
    defineReflectiveTests(UnnecessaryNullComparisonTrueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryNullComparisonFalseTest extends PubPackageResolutionTest {
  test_equal_intLiteral() async {
    await resolveTestCodeWithDiagnostics('''
f(int a, int? b) {
  a == 0;
  0 == a;
  b == 0;
  0 == b;
}
''');
  }

  test_equal_notNullable() async {
    await resolveTestCodeWithDiagnostics('''
f(int a) {
  a == null;
//  ^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullFalse] The operand can't be 'null', so the condition is always 'false'.
  null == a;
//^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullFalse] The operand can't be 'null', so the condition is always 'false'.
}
''');
  }

  test_equal_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f(int? a) {
  a == null;
  null == a;
}
''');
  }

  test_implicitlyAssigned_false() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  int? i;
  i != null;
//^^^^
// [diag.unnecessaryNullComparisonAlwaysNullFalse] The operand must be 'null', so the condition is always 'false'.
  null != i;
//     ^^^^
// [diag.unnecessaryNullComparisonAlwaysNullFalse] The operand must be 'null', so the condition is always 'false'.
}
''');
  }

  test_implicitlyAssigned_true() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  int? i;
  i == null;
//^^^^
// [diag.unnecessaryNullComparisonAlwaysNullTrue] The operand must be 'null', so the condition is always 'true'.
  null == i;
//     ^^^^
// [diag.unnecessaryNullComparisonAlwaysNullTrue] The operand must be 'null', so the condition is always 'true'.
}
''');
  }
}

@reflectiveTest
class UnnecessaryNullComparisonTrueTest extends PubPackageResolutionTest {
  test_equal_invalid_nonNull() async {
    await resolveTestCodeWithDiagnostics('''
f(Unresolved o) {
//^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  int? i = o.nonNull;
  i == null;
  null == i;
}
''');
  }

  test_equal_invalid_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f(Unresolved o) {
//^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  int? i = o.nullable;
  i == null;
  null == i;
}
''');
  }

  test_notEqual_intLiteral() async {
    await resolveTestCodeWithDiagnostics('''
f(int a, int? b) {
  a != 0;
  0 != a;
  b != 0;
  0 != b;
}
''');
  }

  test_notEqual_invalid_nonNull() async {
    await resolveTestCodeWithDiagnostics('''
f(Unresolved o) {
//^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  int? i = o.nonNull;
  i != null;
  null != i;
}
''');
  }

  test_notEqual_invalid_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f(Unresolved o) {
//^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
  int? i = o.nullable;
  i != null;
  null != i;
}
''');
  }

  test_notEqual_notNullable() async {
    await resolveTestCodeWithDiagnostics('''
f(int a) {
  a != null;
//  ^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullTrue] The operand can't be 'null', so the condition is always 'true'.
  null != a;
//^^^^^^^
// [diag.unnecessaryNullComparisonNeverNullTrue] The operand can't be 'null', so the condition is always 'true'.
}
''');
  }

  test_notEqual_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f(int? a) {
  a != null;
  null != a;
}
''');
  }
}
