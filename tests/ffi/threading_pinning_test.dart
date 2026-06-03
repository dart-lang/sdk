// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests Isolate threading API.
//
// VMOptions=--experimental-shared-data

import 'dart:async';
import 'dart:concurrent';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'threading_utils.dart';

@pragma('vm:shared')
late Mutex mutexCondvar;
@pragma('vm:shared')
late ConditionVariable condVar;
@pragma('vm:shared')
bool greetingsReceived = false;

int threadMain(Pointer<Void> data) {
  final new_isolate = Isolate.create(debugName: "helper");
  Expect.isNotNull(new_isolate);
  final SendPort sp = new_isolate.runSync(() {
    Expect.isFalse(Isolate.current.isPinnedToCurrentThread);
    Expect.isTrue(Isolate.pinToCurrentThread());
    Expect.isTrue(Isolate.current.isPinnedToCurrentThread);

    late RawReceivePort rp;
    rp = RawReceivePort((e) {
      print('running RawReceivePort handler $e');

      Expect.isTrue(Isolate.current.isPinnedToCurrentThread);

      Expect.equals("greetings!", e);
      mutexCondvar.runLocked(() {
        greetingsReceived = true;
        condVar.notify();
      });
      rp.close();
    });
    return rp.sendPort;
  });

  Expect.isNotNull(sp);
  sp.send('greetings!');

  // No response is expected until we start running event loop.
  mutexCondvar.runLocked(() => condVar.wait(mutexCondvar, /*timeout_ms=*/ 100));
  Expect.isFalse(greetingsReceived);

  print('=== running event loop for $new_isolate');
  new_isolate.runEventLoopSync();
  mutexCondvar.runLocked(() {
    while (!greetingsReceived) {
      condVar.wait(mutexCondvar);
    }
  });
  Expect.isTrue(greetingsReceived);
  Expect.isTrue(new_isolate.isPinnedToCurrentThread);

  print('=== shutting down');
  new_isolate.shutdownSync();
  return 0;
}

main(List<String> args, SendPort? message) async {
  if (Platform.isWindows) {
    // pthread library loading doesn't work on Windows.
    return;
  }

  asyncStart();

  mutexCondvar = Mutex();
  condVar = ConditionVariable();

  final threadInfo = ThreadInfo();

  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  threadInfo.ptr_data.cast<Uint8>()[0] = 0;
  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        threadMain,
        exceptionalReturn: -1,
      );
  callback.keepIsolateAlive = false;
  pthreadCreate(
    threadInfo.ptr_tid,
    threadInfo.ptr_attr,
    callback.nativeFunction,
    threadInfo.ptr_data.cast<Void>(),
  );

  threadInfo.join();

  asyncEnd();
}
