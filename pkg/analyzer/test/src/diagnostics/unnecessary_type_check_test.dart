// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryTypeCheckFalseTest);
    defineReflectiveTests(UnnecessaryTypeCheckTrueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryTypeCheckFalseTest extends PubPackageResolutionTest {
  test_null_isNot_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
var b = null is! Null;
//      ^^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
''');
  }

  test_typeNonNullable_isNot_same() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a is! int;
//^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}
''');
  }

  test_typeNonNullable_isNot_subtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num a) {
  a is! int;
}
''');
  }

  test_typeNonNullable_isNot_supertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a is! num;
//^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}
''');
  }

  test_typeNullable_isNot_same() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is! int?;
//^^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}
''');
  }

  test_typeNullable_isNot_same_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is! int;
}
''');
  }

  test_typeNullable_isNot_subtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num? a) {
  a is! int?;
}
''');
  }

  test_typeNullable_isNot_subtype_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num? a) {
  a is! int;
}
''');
  }

  test_typeNullable_isNot_supertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is! num?;
//^^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}
''');
  }

  test_typeNullable_isNot_supertype_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is! num;
}
''');
  }

  test_typeParameter_isNot_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {
  a is! dynamic;
//^^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}
''');
  }

  test_typeParameter_isNot_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {
  a is! Object;
}
''');
  }

  test_typeParameter_isNot_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {
  a is! Object?;
//^^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckFalse] Unnecessary type check; the result is always 'false'.
}
''');
  }
}

@reflectiveTest
class UnnecessaryTypeCheckTrueTest extends PubPackageResolutionTest {
  test_expressionInvalidType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(A a) {
//     ^
// [diag.undefinedClass] Undefined class 'A'.
  a is num;
}
''');
  }

  test_null_is_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
var b = null is Null;
//      ^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
''');
  }

  test_type_is_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a is dynamic;
//^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }

  test_type_is_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a is Unresolved;
//     ^^^^^^^^^^
// [diag.typeTestWithUndefinedName] The name 'Unresolved' isn't defined, so it can't be used in an 'is' expression.
}
''');
  }

  test_typeNonNullable_is_same() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a is int;
//^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }

  test_typeNonNullable_is_subtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num a) {
  a is int;
}
''');
  }

  test_typeNonNullable_is_supertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  a is num;
//^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }

  test_typeNullable_is_same() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is int?;
//^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }

  test_typeNullable_is_same_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is int;
}
''');
  }

  test_typeNullable_is_subtype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num? a) {
  a is int?;
}
''');
  }

  test_typeNullable_is_subtype_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num? a) {
  a is int;
}
''');
  }

  test_typeNullable_is_supertype() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is num?;
//^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }

  test_typeNullable_is_supertype_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? a) {
  a is num;
}
''');
  }

  test_typeParameter_is_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {
  a is dynamic;
//^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }

  test_typeParameter_is_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {
  a is Object;
}
''');
  }

  test_typeParameter_is_objectQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T>(T a) {
  a is Object?;
//^^^^^^^^^^^^
// [diag.unnecessaryTypeCheckTrue] Unnecessary type check; the result is always 'true'.
}
''');
  }
}
