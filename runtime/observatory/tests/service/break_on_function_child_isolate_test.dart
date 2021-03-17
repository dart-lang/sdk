// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug --enable-isolate-groups --experimental-enable-isolate-groups-jit
import 'dart:async';
import 'dart:isolate' as dart_isolate;

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 18;
const int LINE_B = 25;
const int LINE_C = 29;

foo(args) { // LINE_A
  final dart_isolate.SendPort sendPort = args[0] as dart_isolate.SendPort;
  sendPort.send('reply from foo');
}

testMain() async {
  final rpResponse = dart_isolate.ReceivePort();
  debugger(); // LINE_B
  await dart_isolate.Isolate.spawn(foo, [rpResponse.sendPort]);
  await rpResponse.first;
  rpResponse.close();
  debugger(); // LINE_C
}

final completerAtFoo = Completer();

final tests = <IsolateTest>[
  hasPausedAtStart,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B + 1),
  (Isolate isolate) async {
    // Set up a listener to wait for child isolate launch and breakpoint events.
    final stream = await isolate.vm.getEventStream(VM.kDebugStream);
    var childIsolate;
    var subscription;
    subscription = stream.listen((ServiceEvent event) async {
      switch (event.kind) {
        case ServiceEvent.kPauseStart:
          childIsolate = event.isolate!;
          await childIsolate.reload();

          Library rootLib = await childIsolate.rootLibrary.load() as Library;
          final foo = rootLib.functions.singleWhere((f) => f.name == 'foo');
          final bpt = await childIsolate.addBreakpointAtEntry(foo);

          expect(bpt is Breakpoint, isTrue);
          childIsolate.resume();
          break;
        case ServiceEvent.kPauseBreakpoint:
          if (childIsolate == event.isolate) {
            ServiceMap stack = await childIsolate.getStack();
            Frame top = stack['frames'][0];
            Script script = await top.location!.script.load() as Script;
            expect(script.tokenToLine(top.location!.tokenPos), equals(LINE_A));

            childIsolate.resume();
            subscription.cancel();
            completerAtFoo.complete();
          }
          break;
      }
    });
  },
  resumeIsolate,
  (Isolate isolate) async {
    await completerAtFoo.future;
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C + 1),
  resumeIsolate,
];

main(args) async {
  runIsolateTests(args, tests,
      testeeConcurrent: testMain, pause_on_start: true);
}
