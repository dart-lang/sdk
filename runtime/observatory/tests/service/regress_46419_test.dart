// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose-debug

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

// DO NOT REORDER BEYOND THIS POINT
bool testing = false;
void printSync() {
  print('sync');
  if (testing) {
    // We'll never reach this code, but setting a breakpoint here will result in
    // the breakpoint being resolved below at line 27.
    print('unreachable'); // line 20, bp1
  }
}

printSyncStar() sync* {
  // We'll end up resolving breakpoint 1 to this location instead of at line 17
  // if #46419 regresses.
  print('sync*');
}

testeeDo() {
  printSync();
  final iterator = printSyncStar();

  print('middle'); // Line 34, bp2

  iterator.toList();
}
// END DO NOT REORDER SECTION

late Breakpoint bp1;
late Breakpoint bp2;

final tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    await isolate.rootLibrary.load();
    final script = isolate.rootLibrary.scripts[0];

    bp1 = await isolate.addBreakpoint(script, 20);
    print("BP1 - $bp1");
    expect(bp1, isNotNull);
    bp2 = await isolate.addBreakpoint(script, 34);
    print("BP2 - $bp2");
    expect(bp2, isNotNull);
  },
  (Isolate isolate) async {
    final stream = await isolate.vm.getEventStream(VM.kDebugStream);
    final done = Completer<bool>();
    stream.listen((event) async {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        var bp = event.breakpoint;
        print('Hit $bp');
        expect(bp, bp2);
        await isolate.resume();
        done.complete(true);
      }
    });
    await resumeIsolate(isolate);
    await done.future;
  }
];

void main([args = const []]) => runIsolateTests(
      args,
      tests,
      testeeConcurrent: testeeDo,
      pause_on_start: true,
    );
