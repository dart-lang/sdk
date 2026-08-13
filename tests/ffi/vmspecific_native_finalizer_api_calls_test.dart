// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
//
// VMOptions=--trace-finalizers

import 'dart:ffi';

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

void main() {
  testDeletePersistentHandleFromFinalizer();
  testDeleteWeakPersistentHandleFromFinalizer();
  print('Done.');
}

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

// C functions.
final newPersistentHandle = ffiTestFunctions
    .lookupFunction<
      Pointer<Void> Function(Handle),
      Pointer<Void> Function(Object)
    >('NewPersistentHandle');

final deletePersistentHandleFinalizer = ffiTestFunctions
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
      'DeletePersistentHandleFinalizer',
    );

final newWeakPersistentHandle = ffiTestFunctions
    .lookupFunction<
      Pointer<Void> Function(Handle),
      Pointer<Void> Function(Object)
    >('NewWeakPersistentHandle');

final deleteWeakPersistentHandleFinalizer = ffiTestFunctions
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
      'DeleteWeakPersistentHandleFinalizer',
    );

class MyClass {
  final int a;
  MyClass(this.a);
}

class MyFinalizable implements Finalizable {
  final int a;
  MyFinalizable(this.a);
}

void testDeletePersistentHandleFromFinalizer() {
  final finalizer = NativeFinalizer(deletePersistentHandleFinalizer);
  final objectToKeepAlive = MyClass(1);
  final persistentHandle = newPersistentHandle(objectToKeepAlive);
  var gcObject = MyFinalizable(2);
  finalizer.attach(gcObject, persistentHandle, detach: gcObject);

  // Lose the object, the finalizer should run.
  gcObject = MyFinalizable(3);
  doGC();
  // Test passes if it does not crash.
}

void testDeleteWeakPersistentHandleFromFinalizer() {
  final finalizer = NativeFinalizer(deleteWeakPersistentHandleFinalizer);
  final objectToKeepAlive = MyClass(1);
  final weakHandle = newWeakPersistentHandle(objectToKeepAlive);

  var gcObject = MyFinalizable(2);
  finalizer.attach(gcObject, weakHandle, detach: gcObject);

  // Lose the object, the finalizer should run.
  gcObject = MyFinalizable(3);
  doGC();
  // Test passes if it does not crash.
}
