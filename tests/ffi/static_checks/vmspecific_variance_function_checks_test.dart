// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// Formatting can break multitests, so don't format them.
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
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'void Function(Pointer<Int64>)' to be 'void Function(Pointer<NativeType>)'.

final p2 =
    ffiTestFunctions.lookup<NativeFunction<NaTyPointerReturnOp>>(returnOpName);
final nonInvariantBinding2 =
    p2.asFunction<Int64PointerReturnOp>();
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'Pointer<Int64> Function()' to be 'Pointer<NativeType> Function()'.

final p3 = Pointer<
    NativeFunction<
        Pointer<NativeFunction<Pointer<NativeType> Function()>>
            Function()>>.fromAddress(0x1234);
final f3 = p3
    .asFunction<
        Pointer<
                NativeFunction<
                    Pointer<Int8> Function()>>
            Function()>();
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
// [cfe] Expected type 'Pointer<NativeFunction<Pointer<Int8> Function()>> Function()' to be 'Pointer<NativeFunction<Pointer<NativeType> Function()>> Function()'.

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
//      ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'void Function(Pointer<Int64>)' can't be assigned to the parameter type 'void Function(Pointer<NativeType>)'.
final implicitDowncast2 =
    Pointer.fromFunction<Int64PointerReturnOp>(
        naTyPointerReturnOp);
//      ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Pointer<NativeType> Function()' can't be assigned to the parameter type 'Pointer<Int64> Function()'.

void main() {}
