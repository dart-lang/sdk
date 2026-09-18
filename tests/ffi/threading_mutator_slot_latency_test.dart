// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/51261.
//
// An isolate group allows at most Scavenger::MaxMutatorThreadCount() threads
// to hold a mutator at once. A thread that blocks in native code keeps its
// slot but is "stealable"; a thread waiting for a slot may steal one, but only
// after kActiveMutatorPreemptionTimeout (120 ms) of uninterrupted waiting.
//
// When the slot holders are native threads that periodically cycle through
// runEventLoopSync (which exits and re-enters the group), each cycle notifies
// the waiter and restarts its timeout, so the steal never happens and the
// waiter only ever runs in the brief hand-off between two cycles. With a
// cycle period shorter than the timeout, a plain message round trip between
// two unrelated isolates degrades from microseconds to the holders' cycle
// period.
//
// VMOptions=--new_gen_semi_max_size=8

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

import 'threading_utils.dart';

// --new_gen_semi_max_size=8 gives MaxMutatorThreadCount() == 4. With this many
// holders every slot is taken before the main isolate or the echo isolate
// wants one.
const int holderCount = 4;

// Shorter than kActiveMutatorPreemptionTimeout, so the holders keep
// interrupting the waiter's timeout.
const int holderCyclePeriodMicros = 20 * 1000;

typedef UsleepNFT = Int32 Function(Uint32);
typedef UsleepFT = int Function(int);
final usleep = DynamicLibrary.process().lookupFunction<UsleepNFT, UsleepFT>(
  'usleep',
);

/// Per holder, in native memory: [0] is the holder's state (see
/// [holderMain]), [1] is set by the main isolate to make it stop.
class Holder {
  final ThreadInfo threadInfo = ThreadInfo();
  final Pointer<Int32> cells = calloc<Int32>(2);
  int get state => cells[0];
  bool get started => state != 0;
  void stop() => cells[1] = 1;
}

// Keeps a holder isolate alive between drains; an isolate without open ports
// exits on its first runEventLoopSync.
late RawReceivePort holderPort;

const int holderRunning = 1;
const int holderDone = 2;
const int holderFailed = 3;

/// Runs on a native thread, outside any isolate: owns an isolate and drains
/// it forever, blocking in native code between drains. The thread holds a
/// mutator slot for as long as the loop lives, and is stealable while it is
/// inside usleep.
///
/// An exception here would silently end the thread through
/// [exceptionalReturn], and a holder that dies is a holder that no longer
/// holds, so the state is reported back through [data] and checked by main.
int holderMain(Pointer<Void> data) {
  final cells = data.cast<Int32>();
  try {
    final isolate = Isolate.create(debugName: 'holder');
    isolate.runSync(() {
      holderPort = RawReceivePort((_) {});
    });
    cells[0] = holderRunning;
    while (cells[1] == 0) {
      usleep(holderCyclePeriodMicros);
      isolate.runEventLoopSync();
    }
    isolate.runSync(() {
      holderPort.close();
    });
    isolate.shutdownSync();
    cells[0] = holderDone;
    return 0;
  } catch (e) {
    cells[0] = holderFailed;
    return -1;
  }
}

Holder startHolder() {
  final holder = Holder();
  final threadInfo = holder.threadInfo;
  Expect.equals(0, pthreadAttrInit(threadInfo.ptr_attr));
  final callback =
      NativeCallable<IntPtr Function(Pointer<Void>)>.isolateGroupBound(
        holderMain,
        exceptionalReturn: -1,
      );
  Expect.equals(
    0,
    pthreadCreate(
      threadInfo.ptr_tid,
      threadInfo.ptr_attr,
      callback.nativeFunction,
      holder.cells.cast<Void>(),
    ),
  );
  return holder;
}

void echoMain(SendPort reply) {
  final port = RawReceivePort();
  port.handler = (message) {
    if (message == null) {
      port.close();
      return;
    }
    reply.send(message);
  };
  reply.send(port.sendPort);
}

Future<double> measureRoundTripMicros(
  SendPort echo,
  StreamIterator<dynamic> replies,
  int rounds,
) async {
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < rounds; i++) {
    echo.send(i);
    Expect.isTrue(await replies.moveNext());
    Expect.equals(i, replies.current);
  }
  return stopwatch.elapsedMicroseconds / rounds;
}

main(List<String> args) async {
  if (Platform.isWindows) {
    // pthread library loading doesn't work on Windows.
    return;
  }
  asyncStart();

  final replyPort = ReceivePort();
  final replies = StreamIterator<dynamic>(replyPort);
  await Isolate.spawn(echoMain, replyPort.sendPort);
  Expect.isTrue(await replies.moveNext());
  final echo = replies.current as SendPort;

  // Warm up and measure with no contention.
  await measureRoundTripMicros(echo, replies, 100);
  final baseline = await measureRoundTripMicros(echo, replies, 200);

  // Start the holders one at a time: each needs to run Dart to set itself up,
  // and once every slot is taken that only works while no other holder is
  // doing the same.
  final holders = <Holder>[];
  for (int i = 0; i < holderCount; i++) {
    final holder = startHolder();
    holders.add(holder);
    while (!holder.started) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  await measureRoundTripMicros(echo, replies, 20);
  final contended = await measureRoundTripMicros(echo, replies, 200);
  print(
    'round trip: ${baseline.toStringAsFixed(1)} us uncontended, '
    '${contended.toStringAsFixed(1)} us with $holderCount holders',
  );
  final holderStates = holders.map((h) => h.state).toList();

  // Tear down before asserting: exiting with an error while the holder
  // threads still cycle through the group ends in a crash rather than a
  // readable failure.
  for (final holder in holders) {
    holder.stop();
  }
  for (final holder in holders) {
    holder.threadInfo.joinAndDestroy();
    Expect.equals(holderDone, holder.state, 'a holder failed to shut down');
    calloc.free(holder.cells);
  }
  echo.send(null);
  replyPort.close();

  for (final state in holderStates) {
    Expect.equals(holderRunning, state, 'a holder thread died');
  }
  // Before the fix this is about holderCyclePeriodMicros per round trip
  // (roughly 1000x the baseline); after it, the two are indistinguishable.
  // The bound leaves a wide margin for slow bots while still failing on the
  // convoy, which is a fixed multiple of the cycle period.
  Expect.isTrue(
    contended < holderCyclePeriodMicros / 4,
    'round trip under contention took ${contended.toStringAsFixed(1)} us, '
    'expected well under ${holderCyclePeriodMicros / 4} us',
  );
  asyncEnd();
}
