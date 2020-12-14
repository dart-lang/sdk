// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--enable-isolate-groups --disable-heap-verification

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import '../../../../../tests/ffi/dylib_utils.dart';

final bool isAOT = Platform.executable.contains('dart_precompiled_runtime');
final bool isolateGropusEnabled =
    Platform.executableArguments.contains('--enable-isolate-groups');
final sdkRoot = Platform.script.resolve('../../../../../');

class Isolate extends Struct {}

abstract class FfiBindings {
  static final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

  static final IGH_MsanUnpoison = ffiTestFunctions.lookupFunction<
      Pointer<Isolate> Function(Pointer<Void>, IntPtr),
      Pointer<Isolate> Function(Pointer<Void>, int)>('IGH_MsanUnpoison');

  static final IGH_CreateIsolate = ffiTestFunctions.lookupFunction<
      Pointer<Isolate> Function(Pointer<Utf8>, Pointer<Void>),
      Pointer<Isolate> Function(
          Pointer<Utf8>, Pointer<Void>)>('IGH_CreateIsolate');

  static final IGH_StartIsolate = ffiTestFunctions.lookupFunction<
      Pointer<Void> Function(Pointer<Isolate>, Int64, Pointer<Utf8>,
          Pointer<Utf8>, IntPtr, Int64, Int64),
      Pointer<Void> Function(Pointer<Isolate>, int, Pointer<Utf8>,
          Pointer<Utf8>, int, int, int)>('IGH_StartIsolate');

  static final Dart_CurrentIsolate = DynamicLibrary.executable()
      .lookupFunction<Pointer<Isolate> Function(), Pointer<Isolate> Function()>(
          "Dart_CurrentIsolate");

  static final Dart_IsolateData = DynamicLibrary.executable().lookupFunction<
      Pointer<Isolate> Function(Pointer<Isolate>),
      Pointer<Isolate> Function(Pointer<Isolate>)>("Dart_IsolateData");

  static final Dart_PostInteger = DynamicLibrary.executable()
      .lookupFunction<IntPtr Function(Int64, Int64), int Function(int, int)>(
          "Dart_PostInteger");

  static Pointer<Isolate> createLightweightIsolate(
      String name, Pointer<Void> peer) {
    final cname = Utf8.toUtf8(name);
    IGH_MsanUnpoison(cname.cast(), name.length + 10);
    try {
      final isolate = IGH_CreateIsolate(cname, peer);
      Expect.isTrue(isolate.address != 0);
      return isolate;
    } finally {
      free(cname);
    }
  }

  static void invokeTopLevelAndRunLoopAsync(
      Pointer<Isolate> isolate, SendPort sendPort, String name,
      {bool? errorsAreFatal, SendPort? onError, SendPort? onExit}) {
    final dartScriptUri = sdkRoot.resolve(
        'runtime/tests/vm/dart/isolates/dart_api_create_lightweight_isolate_test.dart');
    final dartScript = dartScriptUri.toString();
    final libraryUri = Utf8.toUtf8(dartScript);
    IGH_MsanUnpoison(libraryUri.cast(), dartScript.length + 1);
    final functionName = Utf8.toUtf8(name);
    IGH_MsanUnpoison(functionName.cast(), name.length + 1);

    IGH_StartIsolate(
        isolate,
        sendPort.nativePort,
        libraryUri,
        functionName,
        errorsAreFatal == false ? 0 : 1,
        onError != null ? onError.nativePort : 0,
        onExit != null ? onExit.nativePort : 0);

    free(libraryUri);
    free(functionName);
  }
}

void scheduleAsyncInvocation(void fun()) {
  final rp = RawReceivePort();
  rp.handler = (_) {
    try {
      fun();
    } finally {
      rp.close();
    }
  };
  rp.sendPort.send(null);
}

Future withPeerPointer(fun(Pointer<Void> peer)) async {
  final Pointer<Void> peer = Utf8.toUtf8('abc').cast();
  FfiBindings.IGH_MsanUnpoison(peer.cast(), 'abc'.length + 1);
  try {
    await fun(peer);
  } catch (e, s) {
    print('Exception: $e\nStack:$s');
    rethrow;
  } finally {
    // The shutdown callback is called before the exit listeners are notified, so
    // we can validate that a->x has been changed.
    Expect.isTrue(Utf8.fromUtf8(peer.cast()).startsWith('xb'));

    // The cleanup callback is called after after notifying exit listeners. So we
    // wait a little here to ensure the write of the callback has arrived.
    await Future.delayed(const Duration(milliseconds: 100));
    Expect.equals('xbz', Utf8.fromUtf8(peer.cast()));
    free(peer);
  }
}

@pragma('vm:entry-point')
void childTestIsolateData(int mainPort) {
  final peerIsolateData =
      FfiBindings.Dart_IsolateData(FfiBindings.Dart_CurrentIsolate());
  FfiBindings.Dart_PostInteger(mainPort, peerIsolateData.address);
}

Future testIsolateData() async {
  await withPeerPointer((Pointer<Void> peer) async {
    final rp = ReceivePort();
    final exit = ReceivePort();
    final isolate = FfiBindings.createLightweightIsolate('debug-name', peer);
    FfiBindings.invokeTopLevelAndRunLoopAsync(
        isolate, rp.sendPort, 'childTestIsolateData',
        onExit: exit.sendPort);

    Expect.equals(peer.address, await rp.first);
    await exit.first;

    exit.close();
    rp.close();
  });
}

@pragma('vm:entry-point')
void childTestMultipleErrors(int mainPort) {
  scheduleAsyncInvocation(() {
    for (int i = 0; i < 10; ++i) {
      scheduleAsyncInvocation(() => throw 'error-$i');
    }
  });
}

Future testMultipleErrors() async {
  await withPeerPointer((Pointer<Void> peer) async {
    final rp = ReceivePort();
    final accumulatedErrors = <dynamic>[];
    final errors = ReceivePort()..listen(accumulatedErrors.add);
    final exit = ReceivePort();
    final isolate = FfiBindings.createLightweightIsolate('debug-name', peer);
    FfiBindings.invokeTopLevelAndRunLoopAsync(
        isolate, rp.sendPort, 'childTestMultipleErrors',
        errorsAreFatal: false, onError: errors.sendPort, onExit: exit.sendPort);
    await exit.first;
    Expect.equals(10, accumulatedErrors.length);
    for (int i = 0; i < 10; ++i) {
      Expect.equals('error-$i', accumulatedErrors[i][0]);
      Expect.isTrue(
          accumulatedErrors[i][1].contains('childTestMultipleErrors'));
    }

    exit.close();
    errors.close();
    rp.close();
  });
}

@pragma('vm:entry-point')
void childTestFatalError(int mainPort) {
  scheduleAsyncInvocation(() {
    scheduleAsyncInvocation(() => throw 'error-0');
    scheduleAsyncInvocation(() => throw 'error-1');
  });
}

Future testFatalError() async {
  await withPeerPointer((Pointer<Void> peer) async {
    final rp = ReceivePort();
    final accumulatedErrors = <dynamic>[];
    final errors = ReceivePort()..listen(accumulatedErrors.add);
    final exit = ReceivePort();
    final isolate = FfiBindings.createLightweightIsolate('debug-name', peer);
    FfiBindings.invokeTopLevelAndRunLoopAsync(
        isolate, rp.sendPort, 'childTestFatalError',
        errorsAreFatal: true, onError: errors.sendPort, onExit: exit.sendPort);
    await exit.first;
    Expect.equals(1, accumulatedErrors.length);
    Expect.equals('error-0', accumulatedErrors[0][0]);
    Expect.contains('childTestFatalError', accumulatedErrors[0][1]);

    exit.close();
    errors.close();
    rp.close();
  });
}

Future testAot() async {
  await testIsolateData();
  await testMultipleErrors();
  await testFatalError();
}

Future testNotSupported() async {
  dynamic exception;
  try {
    FfiBindings.createLightweightIsolate('debug-name', Pointer.fromAddress(0));
  } catch (e) {
    exception = e;
  }
  Expect.contains(
      'Lightweight isolates are only implemented in AOT mode and need to be '
      'explicitly enabled by passing --enable-isolate-groups.',
      exception.toString());
}

Future testJit() async {
  dynamic exception;
  try {
    FfiBindings.createLightweightIsolate('debug-name', Pointer.fromAddress(0));
  } catch (e) {
    exception = e;
  }
  Expect.contains(
      'Lightweight isolates are not yet ready in JIT mode', exception);
}

Future main(args) async {
  if (!isolateGropusEnabled) {
    await testNotSupported();
    return;
  }
  if (isAOT) {
    await testAot();
  } else {
    await testJit();
  }
}
