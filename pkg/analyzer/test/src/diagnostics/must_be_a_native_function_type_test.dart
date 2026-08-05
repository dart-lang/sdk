// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeANativeFunctionTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MustBeANativeFunctionTypeTest extends PubPackageResolutionTest {
  test_fromFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
class C<T extends Function> {
  void g() {
    Pointer.fromFunction<T>(f);
//                       ^
// [diag.mustBeANativeFunctionType] The type 'T' given to 'fromFunction' must be a valid 'dart:ffi' native function type.
  }
}
''');
  }

  test_lookupFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef S = int Function(int);
typedef F = String Function(String);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
//                   ^
// [diag.mustBeANativeFunctionType] The type 'S' given to 'lookupFunction' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_lookupFunction_Pointer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef S = Void Function(Pointer);
typedef F = void Function(Pointer);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''');
  }

  // TODO(dacoharkes): Should this be an error or not?
  // https://dartbug.com/44594
  test_lookupFunction_PointerNativeFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef S = Void Function(Pointer<NativeFunction>);
typedef F = void Function(Pointer<NativeFunction>);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
//                   ^
// [diag.mustBeANativeFunctionType] The type 'S' given to 'lookupFunction' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_lookupFunction_PointerNativeFunction2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef S = Void Function(Pointer<NativeFunction<Int8 Function()>>);
typedef F = void Function(Pointer<NativeFunction<Int8 Function()>>);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''');
  }

  test_lookupFunction_PointerVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef S = Pointer<Void> Function(Pointer<Void>);
typedef F = Pointer<Void> Function(Pointer<Void>);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''');
  }

  test_lookupFunction_T() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
typedef F = int Function(int);
class C<T extends Function> {
  void f(DynamicLibrary lib, NativeFunction x) {
    lib.lookupFunction<T, F>('g');
//                     ^
// [diag.mustBeANativeFunctionType] The type 'T' given to 'lookupFunction' must be a valid 'dart:ffi' native function type.
  }
}
''');
  }

  test_lookupFunction_VarArgs1() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Doublex2 =
  lib.lookupFunction<
    Double Function(Double, VarArgs<(Double,)>),
    double Function(double, double)
  >(
    "VariadicAt1Doublex2"
  );
''');
  }

  test_lookupFunction_VarArgs2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>),
    int Function(int, int, int, int, int)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''');
  }

  test_lookupFunction_VarArgs3() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>),
    int Function(int, int, int, int, double)
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>)' must be a subtype of 'int Function(int, int, int, int, double)' for 'lookupFunction'.
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''');
  }

  test_lookupFunction_VarArgs4() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, {Int64 named})>),
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, {Int64 named})>)' given to 'lookupFunction' must be a valid 'dart:ffi' native function type.
    int Function(int, int, int, int)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''');
  }

  test_lookupFunction_VarArgs5() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final lib = DynamicLibrary.open('dontcare');
final variadicAt1Int64x5Leaf =
  lib.lookupFunction<
    Int64 Function(Int64, VarArgs<(Int64, Int64, Int64)>, Int64),
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'Int64 Function(Int64, VarArgs<(Int64, Int64, Int64)>, Int64)' given to 'lookupFunction' must be a valid 'dart:ffi' native function type.
    int Function(int, int, int, int, int)
  >(
    "VariadicAt1Int64x5",
    isLeaf:true
  );
''');
  }
}
