// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

// ============================================
// Tests checks on Dart to native (asFunction).
// ============================================

typedef Int64PointerParamOpDart = void Function(Pointer<Int64>);
typedef Int64PointerParamOp = Void Function(Pointer<Int64>);
typedef Int64PointerReturnOp = Pointer<Int64> Function();
typedef NaTyPointerReturnOp = Pointer<NativeType> Function();

final paramOpName = "NativeTypePointerParam";
final returnOpName = "NativeTypePointerReturn";

final DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

final p1 =
    ffiTestFunctions.lookup<NativeFunction<Int64PointerParamOp>>(paramOpName);
final nonInvariantBinding1 = //# 1:  compile-time error
    p1.asFunction<NaTyPointerParamOpDart>(); //# 1:  continued

final p2 =
    ffiTestFunctions.lookup<NativeFunction<NaTyPointerReturnOp>>(returnOpName);
final nonInvariantBinding2 = //# 2:  compile-time error
    p2.asFunction<Int64PointerReturnOp>(); //# 2:  continued

final p3 = Pointer<
    NativeFunction<
        Pointer<NativeFunction<Pointer<NativeType> Function()>>
            Function()>>.fromAddress(0x1234);
final f3 = p3 //# 10:  compile-time error
    .asFunction< //# 10:  continued
        Pointer< //# 10:  continued
                NativeFunction< //# 10:  continued
                    Pointer<Int8> Function()>> //# 10:  continued
            Function()>(); //# 10:  continued

// ===========================================================
// Test check on callbacks from native to Dart (fromFunction).
// ===========================================================

void naTyPointerParamOp(Pointer<NativeType> p) {
  final Pointer<Int8> asInt8 = p.cast();
  asInt8.value = 42;
}

Pointer<Int64> int64PointerReturnOp() {
  return Pointer.fromAddress(0x13370000);
}

final implictDowncast1 = //# 3:  compile-time error
    Pointer.fromFunction<Int64PointerParamOp>(//# 3:  continued
        naTyPointerParamOp); //# 3:  continued
final implictDowncast2 = //# 4:  compile-time error
    Pointer.fromFunction<NaTyPointerReturnOp>(//# 4:  continued
        int64PointerReturnOp); //# 4:  continued

void main() {}
