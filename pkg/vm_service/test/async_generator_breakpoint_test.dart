// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'async_generator_breakpoint_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

Future<void> testAsync(
  VmService service,
  IsolateRef isolateRef,
  TestScriptParser parser,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final Library lib = (await service.getObject(
      isolateId,
      isolate.libraries!
          .firstWhere((l) => l.uri!.contains('async_generator_breakpoint_lib'))
          .id!)) as Library;
  final script = lib.scripts![0];
  final scriptId = script.id!;

  final bp1 = await service.addBreakpoint(
    isolateId,
    scriptId,
    parser.lineForTag('LINE_A'),
  );
  expect(bp1, isNotNull);

  final bp2 = await service.addBreakpoint(
    isolateId,
    scriptId,
    parser.lineForTag('LINE_B'),
  );
  expect(bp2, isNotNull);

  final bp3 = await service.addBreakpoint(
    isolateId,
    scriptId,
    parser.lineForTag('LINE_C'),
  );
  expect(bp3, isNotNull);

  final bp4 = await service.addBreakpoint(
    isolateId,
    scriptId,
    parser.lineForTag('LINE_D'),
  );
  expect(bp4, isNotNull);

  final bp5 = await service.addBreakpoint(
    isolateId,
    scriptId,
    parser.lineForTag('LINE_E'),
  );
  expect(bp5, isNotNull);

  final hits = <Breakpoint>[];
  await service.streamListen(EventStreams.kDebug);

  unawaited(
    service.evaluate(isolateId, lib.id!, 'testerReady = true').then(
      (Response result) async {
        final Obj res =
            await service.getObject(isolateId, (result as InstanceRef).id!);
        print(res);
        expect((res as Instance).valueAsString, equals('true'));
      },
    ),
  );

  final stream = service.onDebugEvent;
  await for (Event event in stream) {
    if (event.kind == EventKind.kPauseBreakpoint) {
      assert(event.pauseBreakpoints!.isNotEmpty);
      final bp = event.pauseBreakpoints!.first;
      hits.add(bp);
      await service.resume(isolateId);

      if (hits.length == 5) break;
    }
  }

  expect(hits, equals([bp1, bp5, bp4, bp2, bp3]));
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('async_generator_breakpoint_lib.dart', args)
        .addCustomTestWithParser(testAsync)
        .run(testeeMain: testee_lib.main);
