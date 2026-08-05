// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExceptionValueTest);
  });
}

@reflectiveTest
class InvalidExceptionValueTest extends PubPackageResolutionTest {
  test_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Void Function(Int8);
void f(int i) {}
void g() {
  Pointer.fromFunction<T>(f, 42);
//                           ^^
// [diag.invalidExceptionValue] The method fromFunction can't have an exceptional return value (the second argument) when the return type of the function is either 'void', 'Handle' or 'Pointer'.
}
''');
  }
}
