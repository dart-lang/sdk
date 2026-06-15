// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastFromNullAlwaysFailsTest);
  });
}

@reflectiveTest
class CastFromNullAlwaysFailsTest extends PubPackageResolutionTest {
  test_castPattern_Null_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null n, num m) {
  (m as int) = n;
// ^^^^^^^^
// [diag.castFromNullAlwaysFails] This cast always throws an exception because the expression always evaluates to 'null'.
}
''');
  }

  test_castPattern_Null_nullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null n, num? m) {
  (m as int?) = n;
//   ^^
// [diag.unnecessaryCastPattern] Unnecessary cast pattern.
}
''');
  }

  test_castPattern_nullable_nullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(num? n, num? m) {
  (m as int?) = n;
}
''');
  }

  test_Null_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null n) {
  n as dynamic;
}
''');
  }

  test_Null_Never() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null n) {
  n as Never;
//^^^^^^^^^^
// [diag.castFromNullAlwaysFails] This cast always throws an exception because the expression always evaluates to 'null'.
}
''');
  }

  test_Null_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null n) {
  n as int;
//^^^^^^^^
// [diag.castFromNullAlwaysFails] This cast always throws an exception because the expression always evaluates to 'null'.
}
''');
  }

  test_Null_nonNullableTypeVariable() async {
    await resolveTestCodeWithDiagnostics('''
void f<T extends Object>(Null n) {
  n as T;
//^^^^^^
// [diag.castFromNullAlwaysFails] This cast always throws an exception because the expression always evaluates to 'null'.
}
''');
  }

  test_Null_nullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(Null n) {
  n as int?;
}
''');
  }

  test_Null_nullableTypeVariable() async {
    await resolveTestCodeWithDiagnostics('''
void f<T>(Null n) {
  n as T;
}
''');
  }

  test_nullable_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
void f(int? n) {
  n as int;
}
''');
  }
}
