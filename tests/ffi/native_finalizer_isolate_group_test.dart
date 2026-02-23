// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that NativeFinalizer can be created inside IsolateGroup.runSync
//
// VMOptions=--experimental-shared-data

import 'dart:ffi';
import 'dart:io';

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

void main() {
  testNativeFinalizerInIsolateGroupRunSync();
}

void testNativeFinalizerInIsolateGroupRunSync() {
  // Load a native library to provide a callback function
  final DynamicLibrary ffiTestFunctions = Platform.isWindows
      ? DynamicLibrary.open('ffi_test_functions.dll')
      : Platform.isMacOS
          ? DynamicLibrary.open('libffi_test_functions.dylib')
          : DynamicLibrary.open('libffi_test_functions.so');

  final finalizerPtr = ffiTestFunctions.lookup<NativeFunction<Void Function(Pointer<Void>)>>('Dart_TestFinalizer_Nop');

  // This should not crash when creating NativeFinalizer in isolate group context
  IsolateGroup.runSync(() {
    final finalizer = NativeFinalizer(finalizerPtr.cast());
    Expect.isNotNull(finalizer);

    // Attach a token
    final token = calloc<Uint8>();
    finalizer.attach(Object(), token.cast());
    calloc.free(token);
  });

  print('NativeFinalizer creation in IsolateGroup.runSync succeeded');
}
