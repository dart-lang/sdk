// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackedAnnotation);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PackedAnnotation extends PubPackageResolutionTest {
  test_error_double() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed(1)
@Packed(1)
// [diag.packedAnnotation][column 1][length 10] Structs must have at most one 'Packed' annotation.
final class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Regress test for http://dartbug.com/45498.
  test_error_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed()
// [diag.packedAnnotationAlignment][column 1][length 9] Only packing to 1, 2, 4, 8, and 16 bytes is supported.
//      ^
// [diag.notEnoughPositionalArgumentsNameSingular] 1 positional argument expected by 'Packed.new', but 0 found.
final class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  test_no_error_struct_no_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  test_no_error_struct_one_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed(1)
final class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Doesn't do anything on Unions.
  test_no_error_union_no_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class C extends Union {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Doesn't do anything on Unions.
  test_no_error_union_one_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed(1)
final class C extends Union {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  /// Doesn't do anything on Unions.
  test_no_error_union_two_annotations() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Packed(1)
@Packed(1)
final class C extends Union {
  external Pointer<Uint8> notEmpty;
}
''');
  }
}
