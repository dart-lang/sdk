// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionTypeCannotBeBoundTest);
  });
}

@reflectiveTest
class GenericFunctionTypeCannotBeBoundTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class C<T extends S Function<S>(S)> {
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 18, 16),
    ]);
  }

  test_genericFunction() async {
    await assertErrorsInCode(r'''
T Function<T extends S Function<S>(S)>(T) fun;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 21, 16),
    ]);
  }

  test_genericFunctionTypedef() async {
    await assertErrorsInCode(r'''
typedef foo = T Function<T extends S Function<S>(S)>(T t);
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 35, 16),
    ]);
  }

  test_parameterOfFunction() async {
    await assertNoErrorsInCode(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_typedef() async {
    await assertErrorsInCode(r'''
typedef T foo<T extends S Function<S>(S)>(T t);
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 24, 16),
    ]);
  }
}
