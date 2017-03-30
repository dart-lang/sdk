// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --verbose-debug
// VMOptions=--error_on_bad_type --error_on_bad_override --verbose-debug --stacktrace-every=55 --stress-async-stacks

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

printSync() {
  print('sync'); // Line 11
}

printAsync() async {
  print('async'); // Line 15
}

printAsyncStar() async* {
  print('async*'); // Line 19
}

printSyncStar() sync* {
  print('sync*'); // Line 23
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

  print('middle'); // Line 41

  future.then((v) => print(v));
  stream.toList();
  iterator.toList();
}

testAsync(Isolate isolate) async {
  await isolate.rootLibrary.load();
  var script = isolate.rootLibrary.scripts[0];

  var bp1 = await isolate.addBreakpoint(script, 11);
  expect(bp1, isNotNull);
  expect(bp1 is Breakpoint, isTrue);
  var bp2 = await isolate.addBreakpoint(script, 15);
  expect(bp2, isNotNull);
  expect(bp2 is Breakpoint, isTrue);
  var bp3 = await isolate.addBreakpoint(script, 19);
  expect(bp3, isNotNull);
  expect(bp3 is Breakpoint, isTrue);
  var bp4 = await isolate.addBreakpoint(script, 23);
  expect(bp4, isNotNull);
  expect(bp4 is Breakpoint, isTrue);
  var bp5 = await isolate.addBreakpoint(script, 41);
  print("BP5 - $bp5");
  expect(bp5, isNotNull);
  expect(bp5 is Breakpoint, isTrue);

  var hits = [];

  isolate.rootLibrary.evaluate('testerReady = true;').then((Instance result) {
    expect(result.valueAsString, equals('true'));
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

var tests = [testAsync];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeDo);
