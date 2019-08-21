// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Helpers for tests which trigger GC in delicate places.

import 'dart:ffi' as ffi;

import 'dylib_utils.dart';

typedef NativeNullaryOp = ffi.Void Function();
typedef NullaryOpVoid = void Function();

typedef NativeUnaryOp = ffi.Void Function(ffi.IntPtr);
typedef UnaryOpVoid = void Function(int);

final ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

final triggerGc = ffiTestFunctions
    .lookupFunction<NativeNullaryOp, NullaryOpVoid>("TriggerGC");

final collectOnNthAllocation = ffiTestFunctions
    .lookupFunction<NativeUnaryOp, UnaryOpVoid>("CollectOnNthAllocation");
