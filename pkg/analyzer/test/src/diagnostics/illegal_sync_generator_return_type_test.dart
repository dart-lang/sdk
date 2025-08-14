// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalSyncGeneratorReturnTypeTest);
  });
}

@reflectiveTest
class IllegalSyncGeneratorReturnTypeTest extends PubPackageResolutionTest {
  test_arrowFunction_iterator() async {
    await assertErrorsInCode(
      '''
Iterable<void> f() sync* => [];
''',
      [error(CompileTimeErrorCode.returnInGenerator, 25, 2)],
    );
  }

  test_function_iterator() async {
    await assertNoErrorsInCode('''
Iterable<void> f() sync* {}
''');
  }

  test_function_nonIterator() async {
    await assertErrorsInCode(
      '''
int f() sync* {}
''',
      [error(CompileTimeErrorCode.illegalSyncGeneratorReturnType, 0, 3)],
    );
  }

  test_function_subclassOfIterator() async {
    await assertErrorsInCode(
      '''
abstract class SubIterator<T> implements Iterator<T> {}
SubIterator<int> f() sync* {}
''',
      [error(CompileTimeErrorCode.illegalSyncGeneratorReturnType, 56, 16)],
    );
  }

  test_function_void() async {
    await assertErrorsInCode(
      '''
void f() sync* {}
''',
      [error(CompileTimeErrorCode.illegalSyncGeneratorReturnType, 0, 4)],
    );
  }

  test_method_nonIterator() async {
    await assertErrorsInCode(
      '''
class C {
  int f() sync* {}
}
''',
      [error(CompileTimeErrorCode.illegalSyncGeneratorReturnType, 12, 3)],
    );
  }

  test_method_subclassOfIterator() async {
    await assertErrorsInCode(
      '''
abstract class SubIterator<T> implements Iterator<T> {}
class C {
  SubIterator<int> f() sync* {}
}
''',
      [error(CompileTimeErrorCode.illegalSyncGeneratorReturnType, 68, 16)],
    );
  }

  test_method_void() async {
    await assertErrorsInCode(
      '''
class C {
  void f() sync* {}
}
''',
      [error(CompileTimeErrorCode.illegalSyncGeneratorReturnType, 12, 4)],
    );
  }
}
