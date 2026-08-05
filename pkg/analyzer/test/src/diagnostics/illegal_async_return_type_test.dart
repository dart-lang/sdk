// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalAsyncReturnTypeTest);
  });
}

@reflectiveTest
class IllegalAsyncReturnTypeTest extends PubPackageResolutionTest {
  test_function_nonFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() async {
// [diag.illegalAsyncReturnType][column 1][length 3] Functions marked 'async' must have a return type which is a supertype of 'Future'.
  return 1;
}
''');
  }

  test_function_nonFuture_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() async {}
''');
  }

  test_function_nonFuture_withReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() async {
// [diag.illegalAsyncReturnType][column 1][length 3] Functions marked 'async' must have a return type which is a supertype of 'Future'.
  return 2;
}
''');
  }

  test_function_subtypeOfFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class SubFuture<T> implements Future<T> {}
SubFuture<int> f() async {
// [diag.illegalAsyncReturnType][column 1][length 14] Functions marked 'async' must have a return type which is a supertype of 'Future'.
  return 0;
}
''');
  }

  test_method_nonFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int m() async {
//^^^
// [diag.illegalAsyncReturnType] Functions marked 'async' must have a return type which is a supertype of 'Future'.
    return 1;
  }
}
''');
  }

  test_method_nonFuture_void() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void m() async {}
}
''');
  }

  test_method_subtypeOfFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class SubFuture<T> implements Future<T> {}
class C {
  SubFuture<int> m() async {
//^^^^^^^^^^^^^^
// [diag.illegalAsyncReturnType] Functions marked 'async' must have a return type which is a supertype of 'Future'.
    return 0;
  }
}
''');
  }
}
