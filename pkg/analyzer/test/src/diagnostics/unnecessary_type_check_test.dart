// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryTypeCheckFalseTest);
    defineReflectiveTests(UnnecessaryTypeCheckTrueTest);
  });
}

@reflectiveTest
class UnnecessaryTypeCheckFalseTest extends PubPackageResolutionTest {
  test_null_isNot_Null() async {
    await assertErrorsInCode(
      r'''
var b = null is! Null;
''',
      [error(diag.unnecessaryTypeCheckFalse, 8, 13)],
    );
  }

  test_typeNonNullable_isNot_same() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  a is! int;
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 18, 9)],
    );
  }

  test_typeNonNullable_isNot_subtype() async {
    await assertNoErrorsInCode(r'''
void f(num a) {
  a is! int;
}
''');
  }

  test_typeNonNullable_isNot_supertype() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  a is! num;
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 18, 9)],
    );
  }

  test_typeNullable_isNot_same() async {
    await assertErrorsInCode(
      r'''
void f(int? a) {
  a is! int?;
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 19, 10)],
    );
  }

  test_typeNullable_isNot_same_nonNullable() async {
    await assertNoErrorsInCode(r'''
void f(int? a) {
  a is! int;
}
''');
  }

  test_typeNullable_isNot_subtype() async {
    await assertNoErrorsInCode(r'''
void f(num? a) {
  a is! int?;
}
''');
  }

  test_typeNullable_isNot_subtype_nonNullable() async {
    await assertNoErrorsInCode(r'''
void f(num? a) {
  a is! int;
}
''');
  }

  test_typeNullable_isNot_supertype() async {
    await assertErrorsInCode(
      r'''
void f(int? a) {
  a is! num?;
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 19, 10)],
    );
  }

  test_typeNullable_isNot_supertype_nonNullable() async {
    await assertNoErrorsInCode(r'''
void f(int? a) {
  a is! num;
}
''');
  }

  test_typeParameter_isNot_dynamic() async {
    await assertErrorsInCode(
      r'''
void f<T>(T a) {
  a is! dynamic;
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 19, 13)],
    );
  }

  test_typeParameter_isNot_object() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {
  a is! Object;
}
''');
  }

  test_typeParameter_isNot_objectQuestion() async {
    await assertErrorsInCode(
      r'''
void f<T>(T a) {
  a is! Object?;
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 19, 13)],
    );
  }
}

@reflectiveTest
class UnnecessaryTypeCheckTrueTest extends PubPackageResolutionTest {
  test_expressionInvalidType() async {
    await assertErrorsInCode(
      r'''
void f(A a) {
  a is num;
}
''',
      [error(diag.undefinedClass, 7, 1)],
    );
  }

  test_null_is_Null() async {
    await assertErrorsInCode(
      r'''
var b = null is Null;
''',
      [error(diag.unnecessaryTypeCheckTrue, 8, 12)],
    );
  }

  test_type_is_dynamic() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  a is dynamic;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 18, 12)],
    );
  }

  test_type_is_unresolved() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  a is Unresolved;
}
''',
      [error(diag.typeTestWithUndefinedName, 23, 10)],
    );
  }

  test_typeNonNullable_is_same() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  a is int;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 18, 8)],
    );
  }

  test_typeNonNullable_is_subtype() async {
    await assertNoErrorsInCode(r'''
void f(num a) {
  a is int;
}
''');
  }

  test_typeNonNullable_is_supertype() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  a is num;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 18, 8)],
    );
  }

  test_typeNullable_is_same() async {
    await assertErrorsInCode(
      r'''
void f(int? a) {
  a is int?;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 19, 9)],
    );
  }

  test_typeNullable_is_same_nonNullable() async {
    await assertNoErrorsInCode(r'''
void f(int? a) {
  a is int;
}
''');
  }

  test_typeNullable_is_subtype() async {
    await assertNoErrorsInCode(r'''
void f(num? a) {
  a is int?;
}
''');
  }

  test_typeNullable_is_subtype_nonNullable() async {
    await assertNoErrorsInCode(r'''
void f(num? a) {
  a is int;
}
''');
  }

  test_typeNullable_is_supertype() async {
    await assertErrorsInCode(
      r'''
void f(int? a) {
  a is num?;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 19, 9)],
    );
  }

  test_typeNullable_is_supertype_nonNullable() async {
    await assertNoErrorsInCode(r'''
void f(int? a) {
  a is num;
}
''');
  }

  test_typeParameter_is_dynamic() async {
    await assertErrorsInCode(
      r'''
void f<T>(T a) {
  a is dynamic;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 19, 12)],
    );
  }

  test_typeParameter_is_object() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {
  a is Object;
}
''');
  }

  test_typeParameter_is_objectQuestion() async {
    await assertErrorsInCode(
      r'''
void f<T>(T a) {
  a is Object?;
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 19, 12)],
    );
  }
}
