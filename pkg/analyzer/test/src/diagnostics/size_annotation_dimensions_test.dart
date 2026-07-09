// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SizeAnnotationDimensions);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SizeAnnotationDimensions extends PubPackageResolutionTest {
  test_error_array_2_3() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  @Array(8, 8)
//^^^^^^^^^^^^
// [diag.sizeAnnotationDimensions] 'Array's must have an 'Array' annotation that matches the dimensions.
  external Array<Array<Array<Uint8>>> a0;
}
''');
  }

  test_error_array_3_2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  @Array(8, 8, 8)
//^^^^^^^^^^^^^^^
// [diag.sizeAnnotationDimensions] 'Array's must have an 'Array' annotation that matches the dimensions.
  external Array<Array<Uint8>> a0;
}
''');
  }

  test_error_multi_2_3() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  @Array.multi([8, 8])
//^^^^^^^^^^^^^^^^^^^^
// [diag.sizeAnnotationDimensions] 'Array's must have an 'Array' annotation that matches the dimensions.
  external Array<Array<Array<Uint8>>> a0;
}
''');
  }

  test_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  @Array(8, 8)
  external Array<Array<Uint8>> a0;
}
''');
  }
}
