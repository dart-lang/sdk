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

noop() {}

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
    () => child.runSync(noop),
    (e) => e is StateError && e.message.contains("Isolate has a message loop"),
  );
  rpChildRequestExit.send(true);
  await rpChildExit.first;
  rpChildExit.close();
  rpChild.close();
}

newRawReceivePort() {
  return RawReceivePort()..keepIsolateAlive = false;
}

newRawReceivePortSendPort() {
  final rp = RawReceivePort()..keepIsolateAlive = false;
  return rp.sendPort;
}

void testRunSyncChecks() {
  final isolate = Isolate.current;
  // Only deeply immutable values can be returned from runSync closure.
  Expect.throwsArgumentError(() {
    isolate.runSync(newRawReceivePort);
  });
  // SendPort can be returned from runSync closure.
  Expect.isNotNull(isolate.runSync(newRawReceivePortSendPort));

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
    () => child.runSync(noop),
    (e) =>
        e is StateError &&
        e.message.contains("Isolate has a message loop running"),
  );
  spChildListening.send('you can exit now');
  await rpChildExit.first;
  rpChildExit.close();
  Expect.throws(
    () => child.runSync(noop),
    (e) =>
        e is StateError &&
        (e.message.contains("Unable to enter the isolate") ||
            e.message.contains("Isolate has a message loop running")),
  );
  rp.close();
}

@pragma('vm:shared')
final dartSetCurrentThreadOwnsIsolate = DynamicLibrary.executable()
    .lookup<NativeFunction<Void Function()>>("Dart_SetCurrentThreadOwnsIsolate")
    .asFunction<void Function()>();

int threadMain(Pointer<Void> data) {
  final new_isolate = Isolate.create(debugName: "helperMain");
  new_isolate.runSync(() {
    dartSetCurrentThreadOwnsIsolate();
  });
  new_isolate.runSync(() {
    print('Hello, new isolate!');
  });
  new_isolate.shutdownSync();
  return 0;
}

@pragma('vm:shared')
final dartNewSendPort = DynamicLibrary.executable()
    .lookup<NativeFunction<Handle Function(Int64)>>("Dart_NewSendPort")
    .asFunction<SendPort Function(int)>();

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

  threadInfo.joinAndDestroy();
}

@pragma('vm:shared')
final Mutex mutexCondvar = Mutex();
@pragma('vm:shared')
final ConditionVariable condVar = ConditionVariable();
@pragma('vm:shared')
final latchOpened = Uint8List(1);
@pragma('vm:shared')
final nativeSendPort = Uint64List(1);

void waitLatch() {
  mutexCondvar.runLocked(() {
    while (latchOpened[0] == 0) {
      condVar.wait(mutexCondvar);
    }
    latchOpened[0] = 0;
  });
}

void openLatch() {
  mutexCondvar.runLocked(() {
    latchOpened[0] = 1;
    condVar.notify();
  });
}

int threadMainPinned(Pointer<Void> data) {
  final new_isolate = Isolate.create(debugName: "helperPinned");

  new_isolate.runSync(() {
    dartSetCurrentThreadOwnsIsolate();
  });
  new_isolate.runSync(() {
    print('Hello, new pinned isolate!');
  });

  try {
    dartNewSendPort(nativeSendPort[0]).send(new_isolate);
  } catch (e) {
    print(e);
  }

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

  nativeSendPort[0] = rp.sendPort.nativePort;

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

  threadInfo.joinAndDestroy();
}

@pragma('vm:shared')
final isHelperInThreadMainWaitingLatchRunning = Uint8List(1);

int threadMainWaitingLatch(Pointer<Void> data) {
  final helper = Isolate.create(debugName: "helperWaitingLatch");

  dartNewSendPort(nativeSendPort[0]).send(helper);

  helper.runSync(() {
    mutexCondvar.runLocked(() {
      isHelperInThreadMainWaitingLatchRunning[0] = 1;
    });
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
  final rp = RawReceivePort((Isolate child_isolate) async {
    print('received $child_isolate');
    while (mutexCondvar.runLocked(
      () => isHelperInThreadMainWaitingLatchRunning[0] == 0,
    )) {
      // Let the thread which should do `helper.runSync`
      // actually do that.
      await Future.delayed(Duration(milliseconds: 10));
    }
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
  nativeSendPort[0] = rp.sendPort.nativePort;

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

  threadInfo.joinAndDestroy();
}

Future<void> testFailRunSyncDifferentIsolateGroup() async {
  final rpFromChild = ReceivePort();
  final rpChildIsDone = ReceivePort();
  final isolate = await Isolate.spawnUri(
    Platform.script,
    <String>["worker"],
    rpFromChild.sendPort,
    onExit: rpChildIsDone.sendPort,
    onError: rpChildIsDone.sendPort,
  );
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
  final spChildControl = (await rpFromChild.first) as SendPort;
  spChildControl.send('please, exit');
  await rpChildIsDone.first;
}

int threadMainCreatesTimer(Pointer<Void> data) {
  final new_isolate = Isolate.create(debugName: "helperMainCreatesTimer");
  new_isolate.runSync(() {
    print(Future.delayed(Duration(seconds: 1)));
  });
  new_isolate.shutdownSync();
  return 0;
}

Future<void> testCreateTimer() async {
  if (Platform.isWindows) {
    return; // pthread is not available on Windows.
  }

  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        threadMainCreatesTimer,
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

  threadInfo.joinAndDestroy();
}

main(List<String> args, SendPort? toParent) async {
  if (toParent != null) {
    Expect.equals(1, args.length);
    Expect.equals("worker", args[0]);
    final rp = ReceivePort();
    // child isolate provides a sendport to parent, so it can tell when to exit
    toParent.send(rp.sendPort);
    await rp.first;
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

  await testCreateTimer();

  asyncEnd();
}
