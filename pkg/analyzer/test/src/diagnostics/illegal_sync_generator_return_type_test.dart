// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
Iterable<void> f() sync* => [];
//                       ^^
// [diag.returnInGenerator] Can't return a value from a generator function that uses the 'async*' or 'sync*' modifier.
''');
  }

  test_function_iterator() async {
    await resolveTestCodeWithDiagnostics(r'''
Iterable<void> f() sync* {}
''');
  }

  test_function_nonIterator() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() sync* {}
// [diag.illegalSyncGeneratorReturnType][column 1][length 3] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
''');
  }

  test_function_subclassOfIterator() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class SubIterator<T> implements Iterator<T> {}
SubIterator<int> f() sync* {}
// [diag.illegalSyncGeneratorReturnType][column 1][length 16] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
''');
  }

  test_function_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() sync* {}
// [diag.illegalSyncGeneratorReturnType][column 1][length 4] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
''');
  }

  test_method_nonIterator() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int f() sync* {}
//^^^
// [diag.illegalSyncGeneratorReturnType] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
}
''');
  }

  test_method_subclassOfIterator() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class SubIterator<T> implements Iterator<T> {}
class C {
  SubIterator<int> f() sync* {}
//^^^^^^^^^^^^^^^^
// [diag.illegalSyncGeneratorReturnType] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
}
''');
  }

  test_method_void() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void f() sync* {}
//^^^^
// [diag.illegalSyncGeneratorReturnType] Functions marked 'sync*' must have a return type that is a supertype of 'Iterable<T>' for some type 'T'.
}
''');
  }
}
