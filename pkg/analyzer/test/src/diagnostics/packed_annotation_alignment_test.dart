// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackedAnnotationAlignment);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PackedAnnotationAlignment extends PubPackageResolutionTest {
  test_error() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed(3)
//      ^
// [diag.packedAnnotationAlignment] Only packing to 1, 2, 4, 8, and 16 bytes is supported.
final class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  test_no_error() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed(1)
final class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }
}
