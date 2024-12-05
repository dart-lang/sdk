// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidTypeArgumentInConstMapTest);
  });
}

@reflectiveTest
class InvalidTypeArgumentInConstMapTest extends PubPackageResolutionTest {
  test_asDefaultValue() async {
    await assertErrorsInCode(r'''
class A<E> {
  final Map<String, List<E Function()>> x;
  const A([this.x = const <String, List<E Function()>>{}]);
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 96, 1,
          messageContains: ["'E'"]),
    ]);
  }

  test_nonConst() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  void m() {
    <String, E>{};
  }
}
''');
  }

  test_typeParameter_inKey() async {
    await assertErrorsInCode(r'''
class A<E> {
  void m() {
    const <E, String>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 37, 1,
          messageContains: ["'E'"]),
    ]);
  }

  test_typeParameter_inKey_deepInside() async {
    await assertErrorsInCode(r'''
class A<E> {
  void m() {
    const <void Function(List<E>), String>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 56, 1,
          messageContains: ["'E'"]),
    ]);
  }

  test_typeParameter_inValue() async {
    await assertErrorsInCode(r'''
class A<E> {
  void m() {
    const <String, E>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 45, 1,
          messageContains: ["'E'"]),
    ]);
  }

  test_typeParameter_inValue_deepInside() async {
    await assertErrorsInCode(r'''
class A<E> {
  void m() {
    const <String, List<E Function()>>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 50, 1,
          messageContains: ["'E'"]),
    ]);
  }
}
