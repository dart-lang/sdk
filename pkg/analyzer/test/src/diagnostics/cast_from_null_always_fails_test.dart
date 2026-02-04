// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
void f(Null n, num m) {
  (m as int) = n;
}
''',
      [error(diag.castFromNullAlwaysFails, 27, 8)],
    );
  }

  test_castPattern_Null_nullable() async {
    await assertErrorsInCode(
      '''
void f(Null n, num? m) {
  (m as int?) = n;
}
''',
      [error(diag.unnecessaryCastPattern, 30, 2)],
    );
  }

  test_castPattern_nullable_nullable() async {
    await assertNoErrorsInCode('''
void f(num? n, num? m) {
  (m as int?) = n;
}
''');
  }

  test_Null_dynamic() async {
    await assertNoErrorsInCode('''
void f(Null n) {
  n as dynamic;
}
''');
  }

  test_Null_Never() async {
    await assertErrorsInCode(
      '''
void f(Null n) {
  n as Never;
}
''',
      [error(diag.castFromNullAlwaysFails, 19, 10)],
    );
  }

  test_Null_nonNullable() async {
    await assertErrorsInCode(
      '''
void f(Null n) {
  n as int;
}
''',
      [error(diag.castFromNullAlwaysFails, 19, 8)],
    );
  }

  test_Null_nonNullableTypeVariable() async {
    await assertErrorsInCode(
      '''
void f<T extends Object>(Null n) {
  n as T;
}
''',
      [error(diag.castFromNullAlwaysFails, 37, 6)],
    );
  }

  test_Null_nullable() async {
    await assertNoErrorsInCode('''
void f(Null n) {
  n as int?;
}
''');
  }

  test_Null_nullableTypeVariable() async {
    await assertNoErrorsInCode('''
void f<T>(Null n) {
  n as T;
}
''');
  }

  test_nullable_nonNullable() async {
    await assertNoErrorsInCode('''
void f(int? n) {
  n as int;
}
''');
  }
}
