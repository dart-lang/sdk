// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate' as I;

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 21;
const LINE_B = LINE_A + 8;
const LINE_C = LINE_B + 2;
const LINE_D = LINE_C + 2;

void isolate(I.SendPort port) {
  final receive = I.RawReceivePort((_) {
    debugger(); // LINE_A
    throw Exception();
  });
  port.send(receive.sendPort);
}

void test() {
  final receive = I.RawReceivePort((port) {
    debugger(); // LINE_B
    port.send(null);
    debugger(); // LINE_C
    port.send(null);
    debugger(); // LINE_D
  });
  I.Isolate.spawn(isolate, receive.sendPort);
}

late final IsolateRef firstIsolate;
late final IsolateRef secondIsolate;

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    firstIsolate = isolateRef;

    // Capture the second isolate when it spawns.
    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = service.onDebugEvent.listen((event) async {
      if (event.kind == EventKind.kPauseStart) {
        secondIsolate = event.isolate!;
        await sub.cancel();
        await service.streamCancel(EventStreams.kDebug);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kDebug);

    // Resume and wait for the second isolate to spawn.
    await resumeIsolate(service, firstIsolate);
    await completer.future;

    // Resume the second isolate.
    await resumeIsolate(service, secondIsolate);

    // First isolate should pause at LINE_B.
    await hasStoppedAtBreakpoint(service, firstIsolate);
    await stoppedAtLine(LINE_B)(service, firstIsolate);
    await resumeIsolate(service, firstIsolate);

    // First isolate should pause at LINE_C and second isolate should pause at
    // LINE_A.
    await Future.wait([
      hasStoppedAtBreakpoint(service, firstIsolate).then(
        (_) => stoppedAtLine(LINE_C)(service, firstIsolate),
      ),
      hasStoppedAtBreakpoint(service, secondIsolate).then(
        (_) => stoppedAtLine(LINE_A)(service, secondIsolate),
      ),
    ]);

    // Resume the second isolate.
    await resumeIsolate(service, secondIsolate);

    // The second isolate should exit due to an exception.
    await hasStoppedAtExit(service, secondIsolate);

    // Resume the first isolate.
    await resumeIsolate(service, firstIsolate);

    // The first isolate should pause at LINE_D.
    await hasStoppedAtBreakpoint(service, firstIsolate);
    await stoppedAtLine(LINE_D)(service, firstIsolate);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'issue_30555_test.dart',
      pause_on_start: true,
      pause_on_exit: true,
      testeeConcurrent: test,
    );
