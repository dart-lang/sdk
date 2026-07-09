// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantTypeArgumentTest);
    defineReflectiveTests(NonConstantTypeArgumentWarningTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantTypeArgumentTest extends PubPackageResolutionTest {
  test_asFunction_R() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef T = int Function(int);
class C<R extends int Function(int)> {
  void f(Pointer<NativeFunction<T>> p) {
    p.asFunction<R>();
//               ^
// [diag.nonConstantTypeArgument] The type arguments to 'asFunction' must be known at compile time, so they can't be type parameters.
  }
}
''');
  }
}

@reflectiveTest
class NonConstantTypeArgumentWarningTest extends PubPackageResolutionTest {
  test_ref_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Uint8()
  external int myField;
}

void main() {
  final pointer = Pointer<MyStruct>.fromAddress(0);
  pointer.ref.myField = 1;
}
''');
  }

  test_ref_class_cascade() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Uint8()
  external int myField;
}

void main() {
  final pointer = Pointer<MyStruct>.fromAddress(0)
    ..ref.myField = 1;
  print(pointer);
}
''');
  }

  test_ref_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

T genericRef<T extends Struct>(Pointer<T> p) =>
    p.ref;
//  ^^^^^
// [diag.nonConstantTypeArgument] The type arguments to 'ref' must be known at compile time, so they can't be type parameters.
''');
  }

  test_refWithFinalizer_class() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Uint8()
  external int myField;
}

void main() {
  final pointer = Pointer<MyStruct>.fromAddress(0);
  pointer.refWithFinalizer(nullptr).myField = 1;
}
''');
  }

  test_refWithFinalizer_class_cascade() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Uint8()
  external int myField;
}

void main() {
  final pointer = Pointer<MyStruct>.fromAddress(0)
    ..refWithFinalizer(nullptr).myField = 1;
  print(pointer);
}
''');
  }

  test_refWithFinalizer_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

T genericRefWithFinalizer<T extends Struct>(Pointer<T> p) =>
    p.refWithFinalizer(nullptr);
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nonConstantTypeArgument] The type arguments to 'refWithFinalizer' must be known at compile time, so they can't be type parameters.
''');
  }
}
