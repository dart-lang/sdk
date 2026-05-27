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

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'dylib_utils.dart';

typedef PthreadAttrInitFT = int Function(Pointer<Char>);
typedef PthreadAttrInitNFT = IntPtr Function(Pointer<Char>);
final pthreadAttrInit = DynamicLibrary.process()
    .lookupFunction<PthreadAttrInitNFT, PthreadAttrInitFT>('pthread_attr_init');

typedef PthreadAttrDestroyFT = int Function(Pointer<Char>);
typedef PthreadAttrDestroyNFT = IntPtr Function(Pointer<Char>);
final pthreadAttrDestroy = DynamicLibrary.process()
    .lookupFunction<PthreadAttrDestroyNFT, PthreadAttrDestroyFT>(
      'pthread_attr_destroy',
    );

typedef PthreadCreateFT =
    int Function(Pointer<IntPtr>, Pointer<Char>, Pointer, Pointer<Void>);
typedef PthreadCreateNFT =
    IntPtr Function(Pointer<IntPtr>, Pointer<Char>, Pointer, Pointer<Void>);
final pthreadCreate = DynamicLibrary.process()
    .lookupFunction<PthreadCreateNFT, PthreadCreateFT>('pthread_create');

typedef PthreadJoinFT = int Function(int, Pointer<Void>);
typedef PthreadJoinNFT = IntPtr Function(IntPtr, Pointer<Void>);
final pthreadJoin = DynamicLibrary.process()
    .lookupFunction<PthreadJoinNFT, PthreadJoinFT>('pthread_join');

@pragma('vm:shared')
int counter = 0;

void testRunSyncOnCurrentIsolate() {
  // Run on current isolate.
  final current_isolate = Isolate.current;
  Expect.equals(
    42,
    current_isolate.runSync(() {
      Expect.equals(
        56,
        Isolate.current.runSync(() {
          return 56;
        }),
      );
      return 42;
    }),
  );
}

Future<void> testFailRunSyncOnAnotherIsolate() async {
  final rpChild = ReceivePort();
  final rpChildExit = ReceivePort();
  final child = await Isolate.spawn(
    (sendPort) async {
      final rp = ReceivePort();
      sendPort.send(rp.sendPort);
      await rp.first;
      rp.close();
    },
    rpChild.sendPort,
    onExit: rpChildExit.sendPort,
  );
  SendPort rpChildRequestExit = await rpChild.first;
  Expect.throws(
    () => child.runSync(() {}),
    (e) => e is StateError && e.message.contains("Isolate has a message loop"),
  );
  rpChildRequestExit.send(true);
  await rpChildExit.first;
  rpChildExit.close();
  rpChild.close();
}

void testRunSyncChecks() {
  final isolate = Isolate.current;
  // Only deeply immutable values can be returned from runSync closure.
  Expect.throwsArgumentError(() {
    isolate.runSync(() => RawReceivePort()..keepIsolateAlive = false);
  });
  // SendPort can be returned from runSync closure.
  Expect.isNotNull(
    isolate.runSync(() {
      final rrp = RawReceivePort()..keepIsolateAlive = false;
      return rrp.sendPort;
    }),
  );

  // Only deeply immutable values can be captured by runSync closure.
  {
    final rp = RawReceivePort();
    Expect.throwsArgumentError(() {
      isolate.runSync(() => rp.sendPort);
    });
    rp.close();
  }
}

Future<void> testFailToRunOnExitedIsolate() async {
  // Enter isolate that never gets to the finish single message loop iteration.
  counter = 0;
  final rp = ReceivePort();
  final rpChildExit = ReceivePort();
  final child = await Isolate.spawn(
    (sendPort) async {
      final rpChildListening = ReceivePort();
      sendPort.send(rpChildListening.sendPort);
      await rpChildListening.first;
    },
    rp.sendPort,
    onExit: rpChildExit.sendPort,
  );
  final spChildListening = await rp.first;
  Expect.throws(
    () => child.runSync(() {
      print('child runSync is running');
    }),
    (e) =>
        e is StateError &&
        e.message.contains("Isolate has a message loop running"),
  );
  spChildListening.send('you can exit now');
  await rpChildExit.first;
  rpChildExit.close();
  Expect.throws(
    () => child.runSync(() {
      print('child runSync is running');
    }),
    (e) => e is StateError && e.message.contains("Unable to enter the isolate"),
  );
  rp.close();
}

@pragma('vm:shared')
final dartSetCurrentThreadOwnsIsolate = DynamicLibrary.executable()
    .lookup<NativeFunction<Void Function()>>("Dart_SetCurrentThreadOwnsIsolate")
    .asFunction<void Function()>();

int threadMain(Pointer<Void> data) {
  final new_isolate = Isolate.create(debugName: "helper");
  new_isolate.runSync(() {
    dartSetCurrentThreadOwnsIsolate();
  });
  new_isolate.runSync(() {
    print('Hello, new isolate!');
  });
  new_isolate.shutdownSync();
  return 0;
}

class ThreadInfo {
  final ptr_attr = calloc<Char>(64); // big enough to fit pthread_attr_t?
  final ptr_tid = calloc<IntPtr>(1);
  final ptr_data = calloc<Int32>(1024);
  final ptr_retval = calloc<IntPtr>(1024);

  void join() {
    Expect.equals(0, pthreadJoin(ptr_tid.value, ptr_retval.cast<Void>()));
    calloc.free(ptr_retval);

    calloc.free(ptr_data);
    calloc.free(ptr_tid);

    Expect.equals(0, pthreadAttrDestroy(ptr_attr));
    calloc.free(ptr_attr);
  }
}

Future<void> testRunSyncOnPinnedToSelfIsolate() async {
  if (Platform.isWindows) {
    return; // pthread is not available on Windows.
  }

  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        threadMain,
        exceptionalReturn: -1,
      );

  final threadInfo = ThreadInfo();
  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  Expect.equals(
    0,
    pthreadCreate(
      threadInfo.ptr_tid,
      threadInfo.ptr_attr,
      callback.nativeFunction,
      threadInfo.ptr_data.cast<Void>(),
    ),
  );

  threadInfo.join();
}

@pragma('vm:shared')
late SendPort sp;
@pragma('vm:shared')
final Mutex mutexCondvar = Mutex();
@pragma('vm:shared')
final ConditionVariable condVar = ConditionVariable();
@pragma('vm:shared')
bool latchOpened = false;

void waitLatch() {
  mutexCondvar.runLocked(() {
    while (!latchOpened) {
      condVar.wait(mutexCondvar);
    }
    latchOpened = false;
  });
}

void openLatch() {
  mutexCondvar.runLocked(() {
    latchOpened = true;
    condVar.notify();
  });
}

int threadMainPinned(Pointer<Void> data) {
  final new_isolate = Isolate.create(debugName: "helper");

  new_isolate.runSync(() {
    dartSetCurrentThreadOwnsIsolate();
  });
  new_isolate.runSync(() {
    print('Hello, new pinned isolate!');
  });
  sp.send(new_isolate);
  waitLatch();

  new_isolate.shutdownSync();
  return 0;
}

Future<void> testFailRunSyncOnPinnedIsolate() async {
  if (Platform.isWindows) {
    return; // pthread is not available on Windows.
  }

  final completer = Completer();
  final rp = RawReceivePort((Isolate child_isolate) {
    print('received $child_isolate');
    Expect.throws(
      () => child_isolate.runSync(() {
        Expect.fail("Should not run");
      }),
      (e) =>
          e is StateError &&
          e.message.contains("Isolate is pinned to a different thread already"),
    );
    openLatch();
    completer.complete();
  });
  sp = rp.sendPort;

  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        threadMainPinned,
        exceptionalReturn: -1,
      );
  final threadInfo = ThreadInfo();
  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  Expect.equals(
    0,
    pthreadCreate(
      threadInfo.ptr_tid,
      threadInfo.ptr_attr,
      callback.nativeFunction,
      threadInfo.ptr_data.cast<Void>(),
    ),
  );

  await completer.future;
  rp.close();

  threadInfo.join();
}

int threadMainWaitingLatch(Pointer<Void> data) {
  final helper = Isolate.create(debugName: "helper");

  sp.send(helper);
  helper.runSync(() {
    waitLatch();
  });
  print('shutting down the isolate');
  helper.shutdownSync();
  return 0;
}

Future<void> testFailRunSyncWithTimeout() async {
  if (Platform.isWindows) {
    return; // pthread is not available on Windows.
  }

  final completer = Completer();
  final rp = RawReceivePort((Isolate child_isolate) {
    print('received $child_isolate');
    Expect.throws(
      () => child_isolate.runSync(() {
        Expect.fail("Should not run");
      }),
      (e) =>
          e is StateError &&
          e.message.contains("Isolate is busy, running on a different thread"),
    );
    openLatch();
    completer.complete();
  });
  sp = rp.sendPort;

  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        threadMainWaitingLatch,
        exceptionalReturn: -1,
      );
  final threadInfo = ThreadInfo();
  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  Expect.equals(
    0,
    pthreadCreate(
      threadInfo.ptr_tid,
      threadInfo.ptr_attr,
      callback.nativeFunction,
      threadInfo.ptr_data.cast<Void>(),
    ),
  );

  await completer.future;
  rp.close();

  threadInfo.join();
}

Future<void> testFailRunSyncDifferentIsolateGroup() async {
  final isolate = await Isolate.spawnUri(Platform.script, <String>[
    "worker",
  ], null);
  Expect.isNotNull(isolate);
  Expect.throws(
    () => isolate.runSync(() {
      Expect.fail("should not run");
    }),
    (e) =>
        e is StateError &&
        e.message.contains(
          "Target isolate should be part of the same isolate group.",
        ),
  );
}

main(List<String> args, List<SendPort>? message) async {
  if (message != null) {
    Expect.equals(1, args.length);
    Expect.equals("worker", args[0]);
    await ReceivePort().first;
    return;
  }

  asyncStart();

  final isolates = List<Future<bool>>.generate(
    30,
    (i) => Isolate.run(() async {
      testRunSyncOnCurrentIsolate();
      await testFailRunSyncOnAnotherIsolate();

      testRunSyncChecks();

      await testFailToRunOnExitedIsolate();
      return true;
    }, debugName: 'worker isolate $i'),
  );
  await Future.wait(isolates);

  await testRunSyncOnPinnedToSelfIsolate();
  await testFailRunSyncOnPinnedIsolate();
  await testFailRunSyncWithTimeout();
  await testFailRunSyncDifferentIsolateGroup();

  asyncEnd();
}
