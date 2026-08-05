// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose-debug

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'regress_46419_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'regress_46419_lib.dart',
      args,
    ).hasPausedAtStart().addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final lineB = parser.lineForTag('LINE_B');
      final lineD = parser.lineForTag('LINE_D');

      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('regress_46419_lib'))
            .id!,
      ) as Library;
      final scriptId = rootLib.scripts!.first.id!;

      final bp1 = await service.addBreakpoint(isolateId, scriptId, lineB);
      print('BP1 - $bp1');
      final bp2 = await service.addBreakpoint(isolateId, scriptId, lineD);
      print('BP2 - $bp2');

      final done = Completer<void>();
      late final StreamSubscription sub;
      sub = service.onDebugEvent.listen((event) async {
        if (event.kind == EventKind.kPauseBreakpoint) {
          expect(event.pauseBreakpoints!.length, 1);
          final bp = event.pauseBreakpoints!.first;
          print('Hit $bp');
          expect(bp, bp2);
          await sub.cancel();
          await service.streamCancel(EventStreams.kDebug);
          await service.resume(isolateId);
          done.complete();
        }
      });
      await service.streamListen(EventStreams.kDebug);
      await service.resume(isolateId);
      await done.future;
    }).run(testeeMain: testee_lib.main, pauseOnStart: true);
