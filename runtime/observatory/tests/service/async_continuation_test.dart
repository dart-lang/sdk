// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override --verbose-debug

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

foo() {}

doSync() {
  foo();  // Line 15
}

doAsync() async {
  foo();  // Line 19
  await null;
}

doAsyncStar() async* {
  foo();  // Line 24
  yield null;
}

testeeDo() {
  debugger();

  doSync();

  doAsync();

  doAsyncStar().listen((_) => null);
}

test(Isolate isolate) async {
  await isolate.rootLibrary.load();
  var script = isolate.rootLibrary.scripts[0];

  var bp1 = await isolate.addBreakpoint(script, 15);
  expect(bp1, isNotNull);
  expect(bp1 is Breakpoint, isTrue);

  var bp2 = await isolate.addBreakpoint(script, 19);
  expect(bp2, isNotNull);
  expect(bp2 is Breakpoint, isTrue);

  var bp3 = await isolate.addBreakpoint(script, 24);
  expect(bp3, isNotNull);
  expect(bp3 is Breakpoint, isTrue);

  isolate.resume();

  var bp1_hit = new Completer();
  var bp2_hit = new Completer();
  var bp3_hit = new Completer();

  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  stream.listen((ServiceEvent event) async {
    print("Event: $event");
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      var bp = event.breakpoint;
      print('Hit $bp');
      if (bp == bp1) {
        await stoppedAtLine(15)(isolate);
        print(event.asyncContinuation);
        expect(event.asyncContinuation.isNull, isTrue);
        isolate.resume();
        bp1_hit.complete(null);
      }
      if (bp == bp2) {
        await stoppedAtLine(19)(isolate);
        print(event.asyncContinuation);
        expect(event.asyncContinuation.isClosure, isTrue);
        isolate.resume();
        bp2_hit.complete(null);
      }
      if (bp == bp3) {
        await stoppedAtLine(24)(isolate);
        print(event.asyncContinuation);
        expect(event.asyncContinuation.isClosure, isTrue);
        isolate.resume();
        bp3_hit.complete(null);
      }
    }
  });

  await bp1_hit.future;
  await bp2_hit.future;
  await bp3_hit.future;
}

main(args) => runIsolateTests(args, [test], testeeConcurrent: testeeDo);
