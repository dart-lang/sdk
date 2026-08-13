// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFieldTypeInStructTest);
  });
}

@reflectiveTest
class InvalidFieldTypeInStructTest extends PubPackageResolutionTest {
  // TODO(dacoharkes): Remove Pointer notEmpty field.
  // https://dartbug.com/44677
  test_instance_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external String str;
//         ^^^^^^
// [diag.invalidFieldTypeInStruct] Fields in struct classes can't have the type 'String'. They can only be declared as 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' or 'Union'.

  external Pointer notEmpty;
}
''');
  }

  // TODO(dacoharkes): Remove Pointer notEmpty field.
  // https://dartbug.com/44677
  test_instance_invalid2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Union {
  external String str;
//         ^^^^^^
// [diag.invalidFieldTypeInStruct] Fields in struct classes can't have the type 'String'. They can only be declared as 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' or 'Union'.

  external Pointer notEmpty;
}
''');
  }

  test_instance_invalid3() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external Pointer? p;
//         ^^^^^^^^
// [diag.invalidFieldTypeInStruct] Fields in struct classes can't have the type 'Pointer?'. They can only be declared as 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' or 'Union'.
}
''');
  }

  test_instance_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external Pointer p;
}
''');
  }

  test_static() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  static String? str;

  external Pointer notEmpty;
}
''');
  }
}
