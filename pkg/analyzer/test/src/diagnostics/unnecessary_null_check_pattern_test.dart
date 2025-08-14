// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullCheckPatternTest);
  });
}

@reflectiveTest
class UnnecessaryNullCheckPatternTest extends PubPackageResolutionTest {
  Future<void> test_interfaceType_nonNullable() async {
    await assertErrorsInCode(
      '''
void f(int x) {
  if (x case var a?) {}
}
''',
      [
        error(WarningCode.unusedLocalVariable, 33, 1),
        error(StaticWarningCode.unnecessaryNullCheckPattern, 34, 1),
      ],
    );
  }

  Future<void> test_interfaceType_nullable() async {
    await assertErrorsInCode(
      '''
void f(int? x) {
  if (x case var a?) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 34, 1)],
    );
  }

  Future<void> test_invalidType_nonNullable() async {
    await assertErrorsInCode(
      '''
UnknownType getValue() => UnknownType();
void f() {
  if (getValue() case final valueX?) {
    print(valueX);
  }
}
''',
      [
        error(CompileTimeErrorCode.undefinedClass, 0, 11),
        error(CompileTimeErrorCode.undefinedFunction, 26, 11),
      ],
    );
  }

  Future<void> test_invalidType_nullable() async {
    await assertErrorsInCode(
      '''
UnknownType? getValue() => null;
void f() {
  if (getValue() case final valueX?) {
    print(valueX);
  }
}
''',
      [error(CompileTimeErrorCode.undefinedClass, 0, 11)],
    );
  }

  Future<void> test_typeParameter_nonNullable() async {
    await assertErrorsInCode(
      '''
class A<T extends num> {
  void f(T x) {
    if (x case var a?) {}
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 60, 1),
        error(StaticWarningCode.unnecessaryNullCheckPattern, 61, 1),
      ],
    );
  }

  Future<void> test_typeParameter_nullable() async {
    await assertErrorsInCode(
      '''
class A<T> {
  void f(T x) {
    if (x case var a?) {}
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 48, 1)],
    );
  }
}
