// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeASubtypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MustBeASubtypeTest extends PubPackageResolutionTest {
  test_fromFunction_firstArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
String f(int i) => i.toString();
void g() {
  Pointer.fromFunction<T>(f, 5);
//                        ^
// [diag.mustBeASubtype] The type 'String Function(int)' must be a subtype of 'T' for 'fromFunction'.
}
''');
  }

  test_fromFunction_secondArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f, '');
//                           ^^
// [diag.mustBeASubtype] The type 'String' must be a subtype of 'Int8' for 'fromFunction'.
}
''');
  }

  test_fromFunction_valid_oneArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Void Function(Int8);
void f(int i) {}
void g() {
  Pointer.fromFunction<T>(f);
}
''');
  }

  test_fromFunction_valid_twoArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f, 42);
}
''');
  }

  test_fromFunction_valid_voidReturnPermissive() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Void Function(Int8);
int f(int i) => i * 2;
void g() {
  Pointer.fromFunction<T>(f);
}
''');
  }

  test_lookupFunction_F() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = Int8 Function(Int8);
class C<F extends int Function(int)> {
  void f(DynamicLibrary lib, NativeFunction x) {
    lib.lookupFunction<T, F>('g');
//                        ^
// [diag.mustBeASubtype] The type 'T' must be a subtype of 'F' for 'lookupFunction'.
  }
}
''');
  }
}
