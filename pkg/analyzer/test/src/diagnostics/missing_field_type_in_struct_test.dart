// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingFieldTypeInStructTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MissingFieldTypeInStructTest extends PubPackageResolutionTest {
  test_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external var str;
//             ^^^
// [diag.missingFieldTypeInStruct] Fields in struct classes must have an explicitly declared type of 'int', 'double' or 'Pointer'.

  external Pointer notEmpty;
}
''');
  }

  test_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external Pointer p;
}
''');
  }
}
