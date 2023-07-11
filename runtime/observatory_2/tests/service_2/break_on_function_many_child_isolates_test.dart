// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// @dart = 2.9
//
// VMOptions=--verbose_debug
//
// Tests breakpoint pausing and resuming with many isolates running and pausing
// simultaneously.

import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:isolate' as dart_isolate;

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 27;
const int LINE_B = 39;
const int LINE_C = 45;

foo(args) { // LINE_A
  print('${dart_isolate.Isolate.current.debugName}: $args');
  final sendPort = args[0] as dart_isolate.SendPort;
  final int i = args[1] as int;
  sendPort.send('reply from foo: $i');
}

int nIsolates = -1;

testMain() async {
  final rps = List<dart_isolate.ReceivePort>.generate(
      nIsolates, (i) => dart_isolate.ReceivePort());
  debugger(); // LINE_B
  for (int i = 0; i < nIsolates; i++) {
    await dart_isolate.Isolate.spawn(foo, [rps[i].sendPort, i],
        debugName: "foo$i");
  }
  print(await Future.wait(rps.map((rp) => rp.first)));
  debugger(); // LINE_C
}

final completerAtFoo = List<Completer>.generate(nIsolates, (_) => Completer());
int completerCount = 0;

Isolate activeIsolate;
final pendingToResume = ListQueue<Isolate>();

final tests = <IsolateTest>[
  hasPausedAtStart,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B + 1),
  (Isolate isolate) async {
    // Set up a listener to wait for child isolate launch and breakpoint events.
    final stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) async {
      switch (event.kind) {
        case ServiceEvent.kPauseStart:
          final childIsolate = event.isolate;
          await childIsolate.reload();

          for (Library lib in childIsolate.libraries) {
            await lib.load();
            if (lib.uri
                .endsWith('break_on_function_many_child_isolates_test.dart')) {
              final foo = lib.functions.singleWhere((f) => f.name == 'foo');
              final bpt = await childIsolate.addBreakpointAtEntry(foo);

              expect(bpt is Breakpoint, isTrue);
              break;
            }
          }
          if (activeIsolate == null) {
            activeIsolate = childIsolate;
            activeIsolate.resume();
          } else {
            pendingToResume.addLast(childIsolate);
          }
          break;
        case ServiceEvent.kPauseBreakpoint:
          final name = event.isolate.name;
          if (!name.startsWith('foo')) {
            break;
          }
          final childIsolate = event.isolate;
          final ndx = int.parse(name.substring('foo'.length));
          final stack = await childIsolate.getStack();
          final top = stack['frames'][0];
          final script = await top.location.script.load() as Script;
          expect(script.tokenToLine(top.location.tokenPos), equals(LINE_A));

          expect(activeIsolate != null, equals(true));
          activeIsolate.resume();
          if ((++completerCount) == nIsolates) {
            subscription.cancel();
          }
          completerAtFoo[ndx].complete();

          if (pendingToResume.isNotEmpty) {
            activeIsolate = pendingToResume.removeFirst();
            activeIsolate.resume();
          }
          break;
      }
    });
  },
  resumeIsolate,
  (Isolate isolate) async {
    await Future.wait(completerAtFoo.map((c) => c.future));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C + 1),
  resumeIsolate,
];

Future runIsolateBreakpointPauseTest(args, nIsolates_) {
  nIsolates = nIsolates_;
  return runIsolateTests(args, tests,
      testeeConcurrent: testMain, pause_on_start: true);
}

main(args) async {
  await runIsolateBreakpointPauseTest(args, /*nIsolates=*/ 30);
}
