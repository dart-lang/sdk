// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiUnwrapTypedDataTest);
  });
}

@reflectiveTest
class FfiUnwrapTypedDataTest extends PubPackageResolutionTest {
  test_fromFunction_argument() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
external int f(Int8List i);
void g() {
  Pointer.fromFunction<Int8 Function(Pointer<Int8>)>(f, 5);
}
''', [
      error(FfiCode.CALLBACK_MUST_NOT_USE_TYPED_DATA, 137, 1),
    ]);
  }

  test_fromFunction_argument_handle() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
external int f(Int8List i);
void g() {
  Pointer.fromFunction<Int8 Function(Handle)>(f, 5);
}
''');
  }

  test_fromFunction_return() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
external Int8List f(int i);
void g() {
  Pointer.fromFunction<Pointer<Int8> Function(Int8)>(f);
}
''', [
      error(FfiCode.CALLBACK_MUST_NOT_USE_TYPED_DATA, 137, 1),
    ]);
  }

  test_lookupFunction_double() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapFloat64List = dylib.lookupFunction<
    Int8 Function(Pointer<Double>, Int64),
    int Function(Float64List, int)>('UnwrapFloat64List', isLeaf: true);
''');
  }

  test_lookupFunction_float() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapFloat32List = dylib.lookupFunction<
    Int8 Function(Pointer<Float>, Int64),
    int Function(Float32List, int)>('UnwrapFloat32List', isLeaf: true);
''');
  }

  test_lookupFunction_leaf() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapInt8List = dylib.lookupFunction<
    Int8 Function(Pointer<Int8>, Int64),
    int Function(Int8List, int)>('UnwrapInt8List', isLeaf: true);
''');
  }

  test_lookupFunction_non_leaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapInt8List = dylib.lookupFunction<
    Int8 Function(Pointer<Int8>, Int64),
    int Function(Int8List, int)>('UnwrapInt8List');
''', [
      error(FfiCode.NON_LEAF_CALL_MUST_NOT_TAKE_TYPED_DATA, 182, 27),
    ]);
  }

  test_lookupFunction_non_leaf_handle() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapInt8List = dylib.lookupFunction<
    Int8 Function(Handle, Int64),
    int Function(Int8List, int)>('UnwrapInt8List');
''');
  }

  test_mismatched_types() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapInt8List = dylib.lookupFunction<
    Int8 Function(Pointer<Uint64>, Int64),
    int Function(Int8List, int)>('UnwrapInt8List', isLeaf: true);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 184, 27),
    ]);
  }

  test_mismatched_types_2() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapInt8List = dylib.lookupFunction<
    Int8 Function(Pointer<Int8>, Int64),
    int Function(Float32List, int)>('UnwrapInt8List', isLeaf: true);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 182, 30),
    ]);
  }

  test_native_leaf() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
@Native<Int8 Function(Pointer<Int8>, Int64)>(
    symbol: 'UnwrapInt8List', isLeaf: true)
external int unwrapInt8List(Int8List list, int length);
''');
  }

  test_native_non_leaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
@Native<Int8 Function(Pointer<Int8>, Int64)>(
    symbol: 'UnwrapInt8List')
external int unwrapInt8List(Int8List list, int length);
''', [
      error(FfiCode.NON_LEAF_CALL_MUST_NOT_TAKE_TYPED_DATA, 45, 131),
    ]);
  }

  test_native_non_leaf_handle() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
@Native<Int8 Function(Handle, Int64)>(
    symbol: 'UnwrapInt8List')
external int unwrapInt8List(Int8List list, int length);
''');
  }

  test_return_lookupFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
final dylib = DynamicLibrary.open('dontcare');
final unwrapInt8List = dylib.lookupFunction<
    Pointer<Int8> Function(),
    Int8List Function()>('UnwrapInt8List', isLeaf: true);
''', [
      error(FfiCode.CALL_MUST_NOT_RETURN_TYPED_DATA, 171, 19),
    ]);
  }

  test_return_native() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
@Native<Pointer<Int8> Function()>(
    symbol: 'UnwrapInt8List', isLeaf: true)
external Int8List unwrapInt8List();
''', [
      error(FfiCode.CALL_MUST_NOT_RETURN_TYPED_DATA, 45, 114),
    ]);
  }

  test_return_native_handle() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
import 'dart:typed_data';
@Native<Handle Function()>(
    symbol: 'UnwrapInt8List')
external Int8List unwrapInt8List();
''');
  }
}
