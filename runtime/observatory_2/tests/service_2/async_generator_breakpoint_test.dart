// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose-debug
// VMOptions=--verbose-debug --stacktrace-every=55 --stress-async-stacks

import 'dart:async';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

printSync() {
  print('sync'); // Line 13
}

printAsync() async {
  await null;
  print('async'); // Line 18
}

printAsyncStar() async* {
  await null;
  print('async*'); // Line 23
}

printSyncStar() sync* {
  print('sync*'); // Line 27
}

var testerReady = false;
testeeDo() {
  // We block here rather than allowing the isolate to enter the
  // paused-on-exit state before the tester gets a chance to set
  // the breakpoints because we need the event loop to remain
  // operational for the async bodies to run.
  print('testee waiting');
  while (!testerReady);

  printSync();
  var future = printAsync();
  var stream = printAsyncStar();
  var iterator = printSyncStar();

  print('middle'); // Line 44

  future.then((v) => print(v));
  stream.toList();
  iterator.toList();
}

Future testAsync(Isolate isolate) async {
  await isolate.rootLibrary.load();
  var script = isolate.rootLibrary.scripts[0];

  var bp1 = await isolate.addBreakpoint(script, 13);
  print("BP1 - $bp1");
  expect(bp1, isNotNull);
  expect(bp1 is Breakpoint, isTrue);
  var bp2 = await isolate.addBreakpoint(script, 18);
  print("BP2 - $bp2");
  expect(bp2, isNotNull);
  expect(bp2 is Breakpoint, isTrue);
  var bp3 = await isolate.addBreakpoint(script, 23);
  print("BP3 - $bp3");
  expect(bp3, isNotNull);
  expect(bp3 is Breakpoint, isTrue);
  var bp4 = await isolate.addBreakpoint(script, 27);
  print("BP4 - $bp4");
  expect(bp4, isNotNull);
  expect(bp4 is Breakpoint, isTrue);
  var bp5 = await isolate.addBreakpoint(script, 44);
  print("BP5 - $bp5");
  expect(bp5, isNotNull);
  expect(bp5 is Breakpoint, isTrue);

  var hits = [];

  isolate.rootLibrary.evaluate('testerReady = true').then((result) {
    print(result);
    expect((result as Instance).valueAsString, equals('true'));
  });

  var stream = await isolate.vm.getEventStream(VM.kDebugStream);
  await for (ServiceEvent event in stream) {
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      var bp = event.breakpoint;
      print('Hit $bp');
      hits.add(bp);
      await isolate.resume();

      if (hits.length == 5) break;
    }
  }

  expect(hits, equals([bp1, bp5, bp4, bp2, bp3]));
}

var tests = <IsolateTest>[testAsync];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeDo);
