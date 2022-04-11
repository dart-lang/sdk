// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
//
// VMOptions=--trace-finalizers

// @dart = 2.9

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

Future<void> testSendAndExitFinalizable() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    (SendPort sendPort) {
      try {
        Isolate.exit(sendPort, MyFinalizable());
      } catch (e) {
        print('Expected exception: $e.');
        Isolate.exit(sendPort, e);
      }
    },
    receivePort.sendPort,
  );
  final result = await receivePort.first;
  Expect.type<ArgumentError>(result);
}

Future<void> testSendAndExitFinalizer() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    (SendPort sendPort) {
      try {
        Isolate.exit(sendPort, MyFinalizable());
      } catch (e) {
        print('Expected exception: $e.');
        Isolate.exit(sendPort, e);
      }
    },
    receivePort.sendPort,
  );
  final result = await receivePort.first;
  Expect.type<ArgumentError>(result);
}
