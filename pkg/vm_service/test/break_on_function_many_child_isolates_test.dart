// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug
//
// Tests breakpoint pausing and resuming with many isolates running and pausing
// simultaneously.

import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:isolate' as dart_isolate;

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 24;
const int LINE_B = 36;
const int LINE_C = 42;

/* LINE_A */ void foo(args) {
  print('${dart_isolate.Isolate.current.debugName}: $args');
  final sendPort = args[0] as dart_isolate.SendPort;
  final int i = args[1] as int;
  sendPort.send('reply from foo: $i');
}

Future<void> testMain() async {
  final rps = List<dart_isolate.ReceivePort>.generate(
      nIsolates, (i) => dart_isolate.ReceivePort());

  print('Isolate count: $nIsolates\n\n\n\n');
  debugger(); // LINE_B
  for (int i = 0; i < nIsolates; i++) {
    await dart_isolate.Isolate.spawn(foo, [rps[i].sendPort, i],
        debugName: "foo$i");
  }
  print(await Future.wait(rps.map((rp) => rp.first)));
  debugger(); // LINE_C
}

int nIsolates = 0;
final completerAtFoo = List<Completer>.generate(nIsolates, (_) => Completer());

Isolate? activeIsolate = null;
final pendingToResume = ListQueue<Isolate>();

late final StreamSubscription<Event> debugStreamSubscription;

final tests = <IsolateTest>[
  hasPausedAtStart,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B + 1),
  (VmService service, IsolateRef isolateRef) async {
    // Set up a listener to wait for child isolate launch and breakpoint events.
    debugStreamSubscription = service.onDebugEvent.listen((Event event) async {
      switch (event.kind) {
        case EventKind.kPauseStart:
          {
            final isolateId = event.isolate!.id!;
            final childIsolate = await service.getIsolate(isolateId);

            for (final libRef in childIsolate.libraries!) {
              final lib =
                  await service.getObject(isolateId, libRef.id!) as Library;

              // Set a breakpoint in the newly started isolate.
              if (lib.uri!.endsWith(
                'break_on_function_many_child_isolates_test.dart',
              )) {
                final foo = lib.functions!.singleWhere((f) => f.name == 'foo');
                await service.addBreakpointAtEntry(isolateId, foo.id!);
                break;
              }
            }

            // Keep track of the list of started isolates and the most recently
            // resumed isolate.
            if (activeIsolate == null) {
              activeIsolate = childIsolate;
              service.resume(isolateId);
            } else {
              pendingToResume.addLast(childIsolate);
            }
            return;
          }
        case EventKind.kPauseBreakpoint:
          {
            final name = event.isolate!.name!;
            if (!name.startsWith('foo')) {
              return;
            }

            final ndx = int.parse(name.substring('foo'.length));
            final isolateId = event.isolate!.id!;

            // Ensure the isolate has stopped at the expected line.
            final stack = await service.getStack(isolateId);
            final top = stack.frames![0];
            final script = await service.getObject(
                isolateId, top.location!.script!.id!) as Script;
            expect(
              script.getLineNumberFromTokenPos(top.location!.tokenPos!),
              LINE_A,
            );

            // Resume the isolate to let it run to completion.
            expect(activeIsolate != null, true);
            await service.resume(activeIsolate!.id!);

            completerAtFoo[ndx].complete();

            // Resume the next isolate from its paused on start state.
            if (pendingToResume.isNotEmpty) {
              activeIsolate = pendingToResume.removeFirst();
              await service.resume(activeIsolate!.id!);
            }
            return;
          }
      }
    });
    await service.streamListen(EventStreams.kDebug);
  },
  resumeIsolate,
  (VmService service, IsolateRef isolateRef) async {
    await Future.wait(completerAtFoo.map((c) => c.future));
    await service.streamCancel(EventStreams.kDebug);
    await debugStreamSubscription.cancel();
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C + 1),
  resumeIsolate,
];

Future runIsolateBreakpointPauseTest(
  List<String> args, {
  required String scriptName,
  required int isolateCount,
}) {
  nIsolates = isolateCount;
  return runIsolateTests(
    args,
    tests,
    scriptName,
    testeeConcurrent: testMain,
    pause_on_start: true,
  );
}

void main(List<String> args) => runIsolateBreakpointPauseTest(
      args,
      scriptName: 'break_on_function_many_child_isolates_test.dart',
      isolateCount: 30,
    );
