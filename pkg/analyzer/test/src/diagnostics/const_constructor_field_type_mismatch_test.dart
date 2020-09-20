// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorFieldTypeMismatchTest);
  });
}

@reflectiveTest
class ConstConstructorFieldTypeMismatchTest extends PubPackageResolutionTest {
  test_assignable_generic() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<int>();
''',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 27, 1),
      ],
    );
  }

  test_assignable_nullValue() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A(null);
''');
  }

  test_assignable_unresolvedFieldAndNullValue() async {
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A(null);
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 40, 10),
    ]);
  }

  test_notAssignable() async {
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH, 57, 14),
    ]);
  }

  test_notAssignable_generic() async {
    await assertErrorsInCode(
      r'''
class C<T> {
  final T x = y;
  const C();
}
const int y = 1;
var v = const C<String>();
''',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 27, 1),
        error(
            CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH, 70, 17),
      ],
    );
  }

  test_notAssignable_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A('foo');
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 40, 10),
    ]);
  }
}
