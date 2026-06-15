// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug
//
// Tests breakpoint pausing and resuming with many isolates running and pausing
// simultaneously.

import 'dart:async';
import 'dart:collection';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'break_on_function_child_isolates_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

int nIsolates = 0;
final completerAtFoo = List<Completer>.generate(nIsolates, (_) => Completer());

Isolate? activeIsolate;
final pendingToResume = ListQueue<Isolate>();

late final StreamSubscription<Event> debugStreamSubscription;

Future runIsolateBreakpointPauseTest(
  List<String> args, {
  required int isolateCount,
}) {
  nIsolates = isolateCount;
  return IsolateTestHarness(
    'break_on_function_child_isolates_lib.dart',
    args,
  )
      .hasPausedAtStart()
      .resumeIsolate()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_B')
      .stepOver()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_B_PLUS_1')
      .addCustomTestWithParser(
        (
          VmService service,
          IsolateRef isolateRef,
          TestScriptParser parser,
        ) async {
          // Set up a listener to wait for child isolate launch and breakpoint events.
          debugStreamSubscription =
              service.onDebugEvent.listen((Event event) async {
            switch (event.kind) {
              case EventKind.kPauseStart:
                {
                  final isolateId = event.isolate!.id!;
                  final childIsolate = await service.getIsolate(isolateId);

                  for (final libRef in childIsolate.libraries!) {
                    final lib = await service.getObject(isolateId, libRef.id!)
                        as Library;

                    // Set a breakpoint in the newly started isolate.
                    if (lib.uri!.endsWith(
                      'break_on_function_child_isolates_lib.dart',
                    )) {
                      final foo =
                          lib.functions!.singleWhere((f) => f.name == 'foo');
                      await service.addBreakpointAtEntry(isolateId, foo.id!);
                      break;
                    }
                  }

                  // Keep track of the list of started isolates and the most recently
                  // resumed isolate.
                  if (activeIsolate == null) {
                    activeIsolate = childIsolate;
                    await service.resume(isolateId);
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
                    isolateId,
                    top.location!.script!.id!,
                  ) as Script;
                  expect(
                    script.getLineNumberFromTokenPos(top.location!.tokenPos!),
                    parser.lineForTag('LINE_A'),
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
      )
      .resumeIsolate()
      .addCustomTest((VmService service, IsolateRef isolateRef) async {
        await Future.wait(completerAtFoo.map((c) => c.future));
        await service.streamCancel(EventStreams.kDebug);
        await debugStreamSubscription.cancel();
      })
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_C')
      .stepOver()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_C_PLUS_1')
      .resumeIsolate()
      .run(
          testeeMain: testee_lib.main,
          pauseOnStart: true,
          testeeEnvironment: {'NUM_CHILD_ISOLATES': isolateCount.toString()});
}

void main([List<String> args = const <String>[]]) =>
    runIsolateBreakpointPauseTest(
      args,
      isolateCount: 30,
    );
