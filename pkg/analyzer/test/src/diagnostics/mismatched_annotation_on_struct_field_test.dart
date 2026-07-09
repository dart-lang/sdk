// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MismatchedAnnotationOnStructFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MismatchedAnnotationOnStructFieldTest extends PubPackageResolutionTest {
  test_double_on_int() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  @Double()
//^^^^^^^^^
// [diag.mismatchedAnnotationOnStructField] The annotation doesn't match the declared type of the field.
  external int x;
}
''');
  }

  test_int32_on_double() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  @Int32()
//^^^^^^^^
// [diag.mismatchedAnnotationOnStructField] The annotation doesn't match the declared type of the field.
  external double x;
}
''');
  }
}
