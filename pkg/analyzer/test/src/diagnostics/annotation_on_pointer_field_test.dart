// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationOnPointerFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnnotationOnPointerFieldTest extends PubPackageResolutionTest {
  test_double() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  @Double()
//^^^^^^^^^
// [diag.annotationOnPointerField] Fields in a struct class whose type is 'Pointer' shouldn't have any annotations.
  external Pointer<Int8> x;
}
''');
  }

  test_int32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  @Int32()
//^^^^^^^^
// [diag.annotationOnPointerField] Fields in a struct class whose type is 'Pointer' shouldn't have any annotations.
  external Pointer<Float> x;
}
''');
  }
}
