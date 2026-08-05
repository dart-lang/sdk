// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalAsyncGeneratorReturnTypeTest);
  });
}

@reflectiveTest
class IllegalAsyncGeneratorReturnTypeTest extends PubPackageResolutionTest {
  test_function_nonStream() async {
    await resolveTestCodeWithDiagnostics(r'''
int f() async* {}
// [diag.illegalAsyncGeneratorReturnType][column 1][length 3] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
''');
  }

  test_function_stream() async {
    await resolveTestCodeWithDiagnostics(r'''
Stream<void> f() async* {}
''');
  }

  test_function_subtypeOfStream() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class SubStream<T> implements Stream<T> {}
SubStream<int> f() async* {}
// [diag.illegalAsyncGeneratorReturnType][column 1][length 14] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
''');
  }

  test_function_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() async* {}
// [diag.illegalAsyncGeneratorReturnType][column 1][length 4] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
''');
  }

  test_method_nonStream() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int f() async* {}
//^^^
// [diag.illegalAsyncGeneratorReturnType] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
}
''');
  }

  test_method_subtypeOfStream() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class SubStream<T> implements Stream<T> {}
class C {
  SubStream<int> f() async* {}
//^^^^^^^^^^^^^^
// [diag.illegalAsyncGeneratorReturnType] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
}
''');
  }

  test_method_void() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void f() async* {}
//^^^^
// [diag.illegalAsyncGeneratorReturnType] Functions marked 'async*' must have a return type that is a supertype of 'Stream<T>' for some type 'T'.
}
''');
  }
}
