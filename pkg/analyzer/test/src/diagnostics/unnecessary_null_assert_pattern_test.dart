// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullAssertPatternTest);
  });
}

@reflectiveTest
class UnnecessaryNullAssertPatternTest extends PubPackageResolutionTest {
  Future<void> test_interfaceType_nonNullable() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a!) {}
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 33, 1),
        error(StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN, 34, 1),
      ],
    );
  }

  Future<void> test_interfaceType_nullable() async {
    await assertErrorsInCode(
      '''
void f(int? x) {
  if (x case var a!) {}
}
''',
      [error(WarningCode.UNUSED_LOCAL_VARIABLE, 34, 1)],
    );
  }

  Future<void> test_invalidType_nonNullable() async {
    await assertErrorsInCode(
      '''
UnknownType getValue() => UnknownType();
void f() {
  if (getValue() case final valueX!) {
    print(valueX);
  }
}
''',
      [
        error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 11),
        error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 26, 11),
      ],
    );
  }

  Future<void> test_invalidType_nullable() async {
    await assertErrorsInCode(
      '''
UnknownType? getValue() => null;
void f() {
  if (getValue() case final valueX!) {
    print(valueX);
  }
}
''',
      [error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 11)],
    );
  }

  Future<void> test_typeParameter_nonNullable() async {
    await assertErrorsInCode(
      '''
class A<T extends num> {
  void f(T x) {
    if (x case var a!) {}
  }
}
''',
      [
        error(WarningCode.UNUSED_LOCAL_VARIABLE, 60, 1),
        error(StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN, 61, 1),
      ],
    );
  }

  Future<void> test_typeParameter_nullable() async {
    await assertErrorsInCode(
      '''
class A<T> {
  void f(T x) {
    if (x case var a!) {}
  }
}
''',
      [error(WarningCode.UNUSED_LOCAL_VARIABLE, 48, 1)],
    );
  }
}
