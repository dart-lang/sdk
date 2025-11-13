// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullComparisonFalseTest);
    defineReflectiveTests(UnnecessaryNullComparisonTrueTest);
  });
}

@reflectiveTest
class UnnecessaryNullComparisonFalseTest extends PubPackageResolutionTest {
  test_equal_intLiteral() async {
    await assertNoErrorsInCode('''
f(int a, int? b) {
  a == 0;
  0 == a;
  b == 0;
  0 == b;
}
''');
  }

  test_equal_notNullable() async {
    await assertErrorsInCode(
      '''
f(int a) {
  a == null;
  null == a;
}
''',
      [
        error(diag.unnecessaryNullComparisonNeverNullFalse, 15, 7),
        error(diag.unnecessaryNullComparisonNeverNullFalse, 26, 7),
      ],
    );
  }

  test_equal_nullable() async {
    await assertNoErrorsInCode('''
f(int? a) {
  a == null;
  null == a;
}
''');
  }

  test_implicitlyAssigned_false() async {
    await assertErrorsInCode(
      '''
f() {
  int? i;
  i != null;
  null != i;
}
''',
      [
        error(diag.unnecessaryNullComparisonAlwaysNullFalse, 18, 4),
        error(diag.unnecessaryNullComparisonAlwaysNullFalse, 36, 4),
      ],
    );
  }

  test_implicitlyAssigned_true() async {
    await assertErrorsInCode(
      '''
f() {
  int? i;
  i == null;
  null == i;
}
''',
      [
        error(diag.unnecessaryNullComparisonAlwaysNullTrue, 18, 4),
        error(diag.unnecessaryNullComparisonAlwaysNullTrue, 36, 4),
      ],
    );
  }
}

@reflectiveTest
class UnnecessaryNullComparisonTrueTest extends PubPackageResolutionTest {
  test_equal_invalid_nonNull() async {
    await assertErrorsInCode(
      '''
f(Unresolved o) {
  int? i = o.nonNull;
  i == null;
  null == i;
}
''',
      [error(diag.undefinedClass, 2, 10)],
    );
  }

  test_equal_invalid_nullable() async {
    await assertErrorsInCode(
      '''
f(Unresolved o) {
  int? i = o.nullable;
  i == null;
  null == i;
}
''',
      [error(diag.undefinedClass, 2, 10)],
    );
  }

  test_notEqual_intLiteral() async {
    await assertNoErrorsInCode('''
f(int a, int? b) {
  a != 0;
  0 != a;
  b != 0;
  0 != b;
}
''');
  }

  test_notEqual_invalid_nonNull() async {
    await assertErrorsInCode(
      '''
f(Unresolved o) {
  int? i = o.nonNull;
  i != null;
  null != i;
}
''',
      [error(diag.undefinedClass, 2, 10)],
    );
  }

  test_notEqual_invalid_nullable() async {
    await assertErrorsInCode(
      '''
f(Unresolved o) {
  int? i = o.nullable;
  i != null;
  null != i;
}
''',
      [error(diag.undefinedClass, 2, 10)],
    );
  }

  test_notEqual_notNullable() async {
    await assertErrorsInCode(
      '''
f(int a) {
  a != null;
  null != a;
}
''',
      [
        error(diag.unnecessaryNullComparisonNeverNullTrue, 15, 7),
        error(diag.unnecessaryNullComparisonNeverNullTrue, 26, 7),
      ],
    );
  }

  test_notEqual_nullable() async {
    await assertNoErrorsInCode('''
f(int? a) {
  a != null;
  null != a;
}
''');
  }
}
