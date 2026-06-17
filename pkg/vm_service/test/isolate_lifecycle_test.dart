// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'isolate_lifecycle_lib.dart';
import 'isolate_lifecycle_lib.dart' as testee_lib;

final resumeCount = spawnCount ~/ 2;

Future<int> numPaused(VmService service) async {
  final vm = await service.getVM();
  int paused = 0;
  for (final isolateRef in vm.isolates!) {
    final isolate = await service.getIsolate(isolateRef.id!);
    if (isolate.pauseEvent != null &&
        isolate.pauseEvent!.kind == EventKind.kPauseExit) {
      paused++;
    }
  }
  return paused;
}

void main([args = const <String>[]]) =>
    VMTestHarness('isolate_lifecycle_lib.dart', args).addTestWithParser(
        (VmService service, TestScriptParser scriptParser) async {
      final vm = await service.getVM();
      final isolates = vm.isolates!;
      expect(isolates.length, 1);
      await hasStoppedAtBreakpoint(service, isolates[0]);
      await stoppedAtLine(scriptParser.lineForTag('LINE_A'))(
          service, isolates[0]);
    }).addTest((VmService service) async {
      int startCount = 0;
      int runnableCount = 0;

      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = service.onIsolateEvent.listen((event) async {
        if (event.kind == EventKind.kIsolateStart) {
          startCount++;
        }
        if (event.kind == EventKind.kIsolateRunnable) {
          runnableCount++;
        }
        if (runnableCount == spawnCount) {
          await sub.cancel();
          await service.streamCancel(EventStreams.kIsolate);
          completer.complete();
        }
      });
      await service.streamListen(EventStreams.kIsolate);

      VM vm = await service.getVM();
      expect(vm.isolates!.length, 1);

      // Resume and wait for the isolates to spawn.
      await service.resume(vm.isolates![0].id!);
      await completer.future;
      expect(startCount, spawnCount);
      expect(runnableCount, spawnCount);
      vm = await service.getVM();
      expect(vm.isolates!.length, spawnCount + 1);
    }).addTest((VmService service) async {
      final completer = Completer<void>();
      if (await numPaused(service) < (spawnCount + 1)) {
        late final StreamSubscription sub;
        sub = service.onDebugEvent.listen((event) async {
          if (event.kind == EventKind.kPauseExit) {
            if (await numPaused(service) == (spawnCount + 1)) {
              await sub.cancel();
              await service.streamCancel(EventStreams.kDebug);
              completer.complete();
            }
          }
        });
        await service.streamListen(EventStreams.kDebug);
        await completer.future;
      }
      expect(await numPaused(service), spawnCount + 1);
    }).addTest((VmService service) async {
      int resumedReceived = 0;
      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = service.onIsolateEvent.listen((event) async {
        if (event.kind == EventKind.kIsolateExit) {
          resumedReceived++;
          if (resumedReceived >= resumeCount) {
            await sub.cancel();
            await service.streamCancel(EventStreams.kIsolate);
            completer.complete();
          }
        }
      });
      await service.streamListen(EventStreams.kIsolate);

      // Resume a subset of the isolates.
      int resumesIssued = 0;

      final vm = await service.getVM();
      final isolateList = vm.isolates!;
      for (final isolate in isolateList) {
        if (isolate.name!.endsWith('main')) {
          continue;
        }
        try {
          resumesIssued++;
          await service.resume(isolate.id!);
        } catch (_) {}
        if (resumesIssued == resumeCount) {
          break;
        }
      }
      await completer.future;
    }).addTest((VmService service) async {
      expect(await numPaused(service), spawnCount + 1 - resumeCount);
    }).run(
      testeeMain: testee_lib.main,
      pauseOnExit: true,
    );
