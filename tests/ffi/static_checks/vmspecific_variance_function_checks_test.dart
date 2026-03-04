// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// dart format off

import 'dart:ffi';


// ============================================
// Tests checks on Dart to native (asFunction).
// ============================================

typedef Int64PointerParamOpDart = void Function(Pointer<Int64>);
typedef Int64PointerParamOp = Void Function(Pointer<Int64>);
typedef NaTyPointerParamOp = Void Function(Pointer<NativeType>);
typedef Int64PointerReturnOp = Pointer<Int64> Function();
typedef NaTyPointerReturnOp = Pointer<NativeType> Function();

final paramOpName = "NativeTypePointerParam";
final returnOpName = "NativeTypePointerReturn";

final DynamicLibrary ffiTestFunctions =
    DynamicLibrary.process();

final p1 =
    ffiTestFunctions.lookup<NativeFunction<Int64PointerParamOp>>(paramOpName);
final nonInvariantBinding1 =
    p1.asFunction<NaTyPointerParamOpDart>();
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
//     ^
// [cfe] Expected type 'invalid-type' to be 'void Function(Pointer<Int64>)', which is the Dart type corresponding to 'NativeFunction<Void Function(Pointer<Int64>)>'.
//                ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'NaTyPointerParamOpDart' isn't a type.

final p2 =
    ffiTestFunctions.lookup<NativeFunction<NaTyPointerReturnOp>>(returnOpName);
final nonInvariantBinding2 =
    p2.asFunction<Int64PointerReturnOp>();
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
//     ^
// [cfe] Expected type 'Pointer<Int64> Function()' to be 'Pointer<NativeType> Function()', which is the Dart type corresponding to 'NativeFunction<Pointer<NativeType> Function()>'.

final p3 = Pointer<
    NativeFunction<
        Pointer<NativeFunction<Pointer<NativeType> Function()>>
            Function()>>.fromAddress(0x1234);
final f3 = p3.asFunction< Pointer< NativeFunction< Pointer<Int8> Function()>> Function()>();
//         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
//            ^
// [cfe] Expected type 'Pointer<NativeFunction<Pointer<Int8> Function()>> Function()' to be 'Pointer<NativeFunction<Pointer<NativeType> Function()>> Function()', which is the Dart type corresponding to 'NativeFunction<Pointer<NativeFunction<Pointer<NativeType> Function()>> Function()>'.

// ===========================================================
// Test check on callbacks from native to Dart (fromFunction).
// ===========================================================

void int64PointerParamOp(Pointer<Int64> p) {
  p.value = 42;
}

Pointer<NativeType> naTyPointerReturnOp() {
  return Pointer.fromAddress(0x13370000);
}

final implicitDowncast1 =
    Pointer.fromFunction<NaTyPointerParamOp>(
        naTyPointerParamOp);
    //  ^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] Undefined name 'naTyPointerParamOp'.
    // [cfe] fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.
final implicitDowncast2 =
    Pointer.fromFunction<Int64PointerReturnOp>(
    //      ^
    // [cfe] Expected type 'Pointer<NativeType> Function()' to be 'Pointer<Int64> Function()', which is the Dart type corresponding to 'NativeFunction<Pointer<Int64> Function()>'.
        naTyPointerReturnOp);
    //  ^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE

void main() {}
