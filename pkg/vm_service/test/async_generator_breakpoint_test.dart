// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/test_helper.dart';

printSync() {
  print('sync'); // Line 11
}

printAsync() async {
  await null;
  print('async'); // Line 16
}

printAsyncStar() async* {
  await null;
  print('async*'); // Line 21
}

printSyncStar() sync* {
  print('sync*'); // Line 25
}

var testerReady = false;
testeeDo() {
  // We block here rather than allowing the isolate to enter the
  // paused-on-exit state before the tester gets a chance to set
  // the breakpoints because we need the event loop to remain
  // operational for the async bodies to run.
  print('testee waiting');
  while (!testerReady) {}

  printSync();
  final future = printAsync();
  final stream = printAsyncStar();
  final iterator = printSyncStar();

  print('middle'); // Line 42

  future.then((v) => print(v));
  stream.toList();
  iterator.toList();
}

Future testAsync(VmService service, IsolateRef isolateRef) async {
  final isolate = await service.getIsolate(isolateRef.id);
  final Library lib = await service.getObject(isolate.id, isolate.rootLib.id);
  final script = lib.scripts[0];

  final bp1 = await service.addBreakpoint(isolate.id, script.id, 11);
  expect(bp1, isNotNull);
  expect(bp1 is Breakpoint, isTrue);

  final bp2 = await service.addBreakpoint(isolate.id, script.id, 16);
  expect(bp2, isNotNull);
  expect(bp2 is Breakpoint, isTrue);

  final bp3 = await service.addBreakpoint(isolate.id, script.id, 21);
  expect(bp3, isNotNull);
  expect(bp3 is Breakpoint, isTrue);

  final bp4 = await service.addBreakpoint(isolate.id, script.id, 25);
  expect(bp4, isNotNull);
  expect(bp4 is Breakpoint, isTrue);

  final bp5 = await service.addBreakpoint(isolate.id, script.id, 42);
  expect(bp5, isNotNull);
  expect(bp5 is Breakpoint, isTrue);

  final hits = <Breakpoint>[];
  await service.streamListen(EventStreams.kDebug);

  // ignore: unawaited_futures
  service
      .evaluate(isolate.id, lib.id, 'testerReady = true')
      .then((Response result) async {
    Obj res = await service.getObject(isolate.id, (result as InstanceRef).id);
    print(res);
    expect((res as Instance).valueAsString, equals('true'));
  });

  final stream = service.onDebugEvent;
  await for (Event event in stream) {
    if (event.kind == EventKind.kPauseBreakpoint) {
      assert(event.pauseBreakpoints.isNotEmpty);
      final bp = event.pauseBreakpoints.first;
      hits.add(bp);
      await service.resume(isolate.id);

      if (hits.length == 5) break;
    }
  }

  expect(hits, equals([bp1, bp5, bp4, bp2, bp3]));
}

final tests = <IsolateTest>[testAsync];

main([args = const <String>[]]) =>
    runIsolateTests(args, tests, testeeConcurrent: testeeDo);
