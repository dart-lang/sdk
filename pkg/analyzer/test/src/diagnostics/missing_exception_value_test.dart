// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingExceptionValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingExceptionValueTest extends PubPackageResolutionTest {
  test_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f);
//        ^^^^^^^^^^^^
// [diag.missingExceptionValue] The method fromFunction must have an exceptional return value (the second argument) when the return type of the function is neither 'void', 'Handle', nor 'Pointer'.
}
''');
  }
}
