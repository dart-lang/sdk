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
import 'dart:typed_data';

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'threading_utils.dart';

int foo = 42;

@pragma('vm:shared')
final mutexCondvar = Mutex();
@pragma('vm:shared')
final condVar = ConditionVariable();
@pragma('vm:shared')
final greetingsReceived = Uint64List(1);

int threadMain(Pointer<Void> data) {
  final pthreadSelf = DynamicLibrary.process()
      .lookupFunction<PthreadSelfNFT, PthreadSelfFT>('pthread_self');
  final self = pthreadSelf();
  final i = data.cast<Uint64>()[0];
  // print('threadMain started with $data i:$i pthreadid $self');
  final new_isolate = Isolate.create(debugName: "helper");
  Expect.isNotNull(new_isolate);
  final SendPort sp = new_isolate.runSync(() {
    late RawReceivePort rp;
    rp = RawReceivePort((e) {
      print('running RawReceivePort handler $e');
      final pthreadSelf = DynamicLibrary.process()
          .lookupFunction<PthreadSelfNFT, PthreadSelfFT>('pthread_self');
      final isolate_self = pthreadSelf();
      print('=== receivePort handler received $e on pthreadid $self');
      Expect.equals(self, isolate_self);

      Expect.equals("greetings!", e);
      mutexCondvar.runLocked(() {
        greetingsReceived[0] |= (1 << i);
        condVar.notify();
      });
      rp.close();
    });
    return rp.sendPort;
  });

  Expect.isNotNull(sp);
  sp.send('greetings!');

  // No response is expected until we start running event loop.
  int bit = 0;
  mutexCondvar.runLocked(() {
    condVar.wait(mutexCondvar, /*timeout_ms=*/ 100);
    bit = ((1 << i) & greetingsReceived[0]);
  });
  Expect.isFalse(bit != 0);

  // print('=== running event loop for $new_isolate');
  new_isolate.runEventLoopSync();
  mutexCondvar.runLocked(() {
    while (((1 << i) & greetingsReceived[0]) == 0) {
      condVar.wait(mutexCondvar);
    }
    bit = ((1 << i) & greetingsReceived[0]);
  });
  Expect.isTrue(bit != 0);

  // print('=== running runSync again');
  new_isolate.runSync(() {
    print('=== hi, kuka ${++foo}!');
    Expect.equals(43, foo);
  });

  // print('=== shutting down');
  new_isolate.shutdownSync();
  return 0;
}

ThreadInfo testRunOnNewIsolateOnNewThread(
  int i,
  int Function(Pointer<Void>) threadMain,
) {
  final threadInfo = ThreadInfo();

  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  threadInfo.ptr_data.cast<Uint64>()[0] = i;
  print(
    '=== ptr_data: ${threadInfo.ptr_data.address.toRadixString(16)}, i: $i',
  );
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
  return threadInfo;
}

Future<void> testRunEventLoopManyThreads({int numThreads = 63}) async {
  if (Platform.isWindows) {
    // pthread library loading doesn't work on Windows.
    return;
  }
  final threadInfos = <ThreadInfo>[];
  final repliedMask = (1 << numThreads) - 1;
  print('repliedMask: ${repliedMask.toRadixString(16)}');
  for (int i = 0; i < numThreads; i++) {
    threadInfos.add(testRunOnNewIsolateOnNewThread(i, threadMain));
  }
  mutexCondvar.runLocked(() {
    while (greetingsReceived[0] < repliedMask) {
      condVar.wait(mutexCondvar);
      print('main received ${greetingsReceived[0].toRadixString(16)}');
    }
  });
  print('main is happy received ${greetingsReceived[0].toRadixString(16)}');

  for (ThreadInfo threadInfo in threadInfos) {
    threadInfo.joinAndDestroy();
  }
}

Future<void> testFailRunEventLoopFromIsolate() async {
  Expect.throws(
    () {
      Isolate.current.runEventLoopSync();
    },
    (e) =>
        e is StateError &&
        e.message.contains("Should be invoked outside of an isolate"),
  );
}

main(List<String> args, SendPort? message) async {
  if (message != null) {
    Expect.equals(1, args.length);
    Expect.equals("worker", args[0]);
    await ReceivePort().first;
    return;
  }
  asyncStart();

  await testRunEventLoopManyThreads(numThreads: 63);
  await testFailRunEventLoopFromIsolate();

  asyncEnd();
}
