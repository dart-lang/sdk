// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
//
// VMOptions=--trace-finalizers

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

void main() async {
  await testSendAndExitFinalizable();
  await testSendAndExitFinalizer();
  await testFinalizerRunsOnIsolateShutdown();
  await testDeletePersistentHandleOnIsolateShutdown();
  await testDeleteWeakPersistentHandleOnIsolateShutdown();
  print('End of test, shutting down.');
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

void runIsolateAttachFinalizer(int address) {
  final token = Pointer<IntPtr>.fromAddress(address);
  createAndLoseFinalizable(token);
  print('Isolate done.');
}

Future<void> testFinalizerRunsOnIsolateShutdown() async {
  await using((Arena allocator) async {
    final token = allocator<IntPtr>();
    Expect.equals(0, token.value);
    final portExitMessage = ReceivePort();
    await Isolate.spawn(
      runIsolateAttachFinalizer,
      token.address,
      onExit: portExitMessage.sendPort,
    );
    await portExitMessage.first;

    doGC();
    Expect.equals(42, token.value);
  });
}

void runIsolateDeletePersistentHandleOnShutdown(int objectAddress) {
  final finalizer = NativeFinalizer(deletePersistentHandleFinalizer);
  final persistentHandle = Pointer<Void>.fromAddress(objectAddress);
  final objectToFinalize = MyFinalizableObject();
  finalizer.attach(
    objectToFinalize,
    persistentHandle,
    detach: objectToFinalize,
  );
}

Future<void> testDeletePersistentHandleOnIsolateShutdown() async {
  final objectToKeepAlive =
      Object(); // Keep a strong reference to ensure the handle stays alive
  final persistentHandle = newPersistentHandle(objectToKeepAlive);
  final portExitMessage = ReceivePort();
  await Isolate.spawn(
    runIsolateDeletePersistentHandleOnShutdown,
    persistentHandle.address,
    onExit: portExitMessage.sendPort,
  );
  await portExitMessage.first; // Wait for the isolate to exit
  doGC();

  // The test passes if no crash occurred. We can't directly verify the handle deletion
  // from outside the isolate, but the lack of a crash indicates success.
  print('Persistent handle deletion test on shutdown completed cleanly.');
}

void runIsolateDeleteWeakPersistentHandleOnShutdown(int objectAddress) {
  final finalizer = NativeFinalizer(deleteWeakPersistentHandleFinalizer);
  final weakHandle = Pointer<Void>.fromAddress(objectAddress);
  final objectToFinalize = MyFinalizableObject();
  finalizer.attach(objectToFinalize, weakHandle, detach: objectToFinalize);
  print('Isolate for weak persistent handle deletion done.');
}

Future<void> testDeleteWeakPersistentHandleOnIsolateShutdown() async {
  final objectToKeepAlive =
      Object(); // Keep a strong reference to ensure the handle stays alive
  final weakHandle = newWeakPersistentHandle(objectToKeepAlive);
  final portExitMessage = ReceivePort();
  await Isolate.spawn(
    runIsolateDeleteWeakPersistentHandleOnShutdown,
    weakHandle.address,
    onExit: portExitMessage.sendPort,
  );
  await portExitMessage.first; // Wait for the isolate to exit
  doGC();

  // The test passes if no crash occurred.
  print('Weak persistent handle deletion test on shutdown completed cleanly.');
}

Future<void> testSendAndExitFinalizable() async {
  final receivePort = ReceivePort();
  await Isolate.spawn((SendPort sendPort) {
    try {
      Isolate.exit(sendPort, MyFinalizable());
    } catch (e) {
      print('Expected exception: $e.');
      Isolate.exit(sendPort, e.toString());
    }
  }, receivePort.sendPort);
  final result = await receivePort.first;
  Expect.contains("Invalid argument: is unsendable", result);
}

Future<void> testSendAndExitFinalizer() async {
  final receivePort = ReceivePort();
  await Isolate.spawn((SendPort sendPort) {
    try {
      Isolate.exit(sendPort, MyFinalizable());
    } catch (e) {
      print('Expected exception: $e.');
      Isolate.exit(sendPort, e.toString());
    }
  }, receivePort.sendPort);
  final result = await receivePort.first;
  Expect.contains("Invalid argument: is unsendable", result);
}

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

class MyFinalizableObject implements Finalizable {}
