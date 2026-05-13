// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingAnnotationOnStructFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingAnnotationOnStructFieldTest extends PubPackageResolutionTest {
  test_missing_int() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external int x;
//         ^^^
// [diag.missingAnnotationOnStructField] Fields of type 'int' in a subclass of 'Struct' must have an annotation indicating the native type.
}
''');
  }

  test_notMissing() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  @Int32()
  external int x;
}
''');
  }
}
