// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

int counter = 0;
const LINE_A = 20;
const LINE_B = LINE_A + 1;
const LINE_C = LINE_A - 2;

void periodicTask(_) {
  counter++;
  counter++; // Line 19.  We set our breakpoint here.
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  new Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

Future<void> waitForEvent(VmService service, String eventKind) {
  final completer = Completer<void>();
  late final subscription;
  subscription = service.onDebugEvent.listen((Event event) {
    if (event.kind == eventKind) {
      subscription.cancel();
      completer.complete();
    }
  });
  return completer.future;
}

final tests = <IsolateTest>[
  // Initialize stream.
  (VmService service, IsolateRef isolateRef) async {
    await service.streamListen(EventStreams.kDebug);
  },
  // Pause
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final event = waitForEvent(service, EventKind.kPauseInterrupted);
    await service.pause(isolateId);
    await event;
  },

  // Resume
  resumeIsolate,

  // Add breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final scriptId = rootLib.scripts![0].id!;
    final script = await service.getObject(isolateId, scriptId) as Script;

    final event = waitForEvent(service, EventKind.kPauseBreakpoint);

    // Add the breakpoint.
    final bpt = await service.addBreakpoint(isolateId, scriptId, LINE_A);
    expect(bpt.location!.script!.id, scriptId);
    expect(script.getLineNumberFromTokenPos(bpt.location!.tokenPos), LINE_A);

    isolate = await service.getIsolate(isolateId);
    expect(isolate.breakpoints!.length, 1);

    await event; // Wait for breakpoint events.
  },

  // We are at the breakpoint on LINE_A.
  stoppedAtLine(LINE_A),

  // Stepping
  (VmService service, IsolateRef isolateRef) async {
    final event = waitForEvent(service, EventKind.kPauseBreakpoint);
    await service.resume(isolateRef.id!, step: StepOption.kOver);
    await event; // Wait for breakpoint events.
  },

  // We are now at line LINE_B.
  stoppedAtLine(LINE_B),

  // Remove breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var isolate = await service.getIsolate(isolateId);

    // Set up a listener to wait for breakpoint events.
    final event = waitForEvent(service, EventKind.kBreakpointRemoved);

    expect(isolate.breakpoints!.length, 1);
    final bpt = isolate.breakpoints!.first;
    await service.removeBreakpoint(isolateId, bpt.id!);
    await event;

    isolate = await service.getIsolate(isolateId);
    expect(isolate.breakpoints!.length, 0);
  },

  // Resume
  resumeIsolate,

  // Add breakpoint at function entry
  (VmService service, IsolateRef isolateRef) async {
    // Set up a listener to wait for breakpoint events.
    final event = waitForEvent(service, EventKind.kPauseBreakpoint);

    final isolateId = isolateRef.id!;
    var isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;

    // Find a specific function.
    final function = rootLib.functions!.firstWhere(
      (f) => f.name == 'periodicTask',
    );

    // Add the breakpoint at function entry
    final bpt = await service.addBreakpointAtEntry(isolateId, function.id!);

    final script =
        await service.getObject(isolateId, bpt.location!.script!.id!) as Script;
    expect(script.uri, endsWith('debugging_test.dart'));
    expect(script.getLineNumberFromTokenPos(bpt.location!.tokenPos), LINE_C);

    isolate = await service.getIsolate(isolateId);
    expect(isolate.breakpoints!.length, 1);

    await event; // Wait for breakpoint events.
  },

  // We are now at line LINE_C, the entrypoint for periodicTask.
  stoppedAtLine(LINE_C),
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'debugging_test.dart',
      testeeBefore: startTimer,
    );
