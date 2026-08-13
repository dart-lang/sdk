// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'debugging_lib.dart' as testee_lib;

Future<void> waitForEvent(VmService service, String eventKind) {
  final completer = Completer<void>();
  late final StreamSubscription<Event> subscription;
  subscription = service.onDebugEvent.listen((Event event) {
    if (event.kind == eventKind) {
      subscription.cancel();
      completer.complete();
    }
  });
  return completer.future;
}

void main([List<String> args = const <String>[]]) => IsolateTestHarness(
      'debugging_lib.dart',
      args,
    )
        // Initialize stream.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          await service.streamListen(EventStreams.kDebug);
        })
        // Pause
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final event = waitForEvent(service, EventKind.kPauseInterrupted);
          await service.pause(isolateId);
          await event;
        })
        // Resume
        .resumeIsolate()
        // Add breakpoint
        .addCustomTestWithParser(
          (service, isolateRef, scriptParser) async {
            final isolateId = isolateRef.id!;
            var isolate = await service.getIsolate(isolateId);
            final rootLib = await service.getObject(
                isolateId,
                isolate.libraries!
                    .firstWhere((l) => l.uri!.contains('debugging_lib'))
                    .id!) as Library;
            final scriptId = rootLib.scripts![0].id!;
            final script =
                await service.getObject(isolateId, scriptId) as Script;

            final event = waitForEvent(service, EventKind.kPauseBreakpoint);

            // Add the breakpoint.
            final lineA = scriptParser.lineForTag('LINE_A');
            final bpt = await service.addBreakpoint(isolateId, scriptId, lineA);
            expect(bpt.location!.script!.id, scriptId);
            expect(
              script.getLineNumberFromTokenPos(bpt.location!.tokenPos),
              lineA,
            );

            isolate = await service.getIsolate(isolateId);
            expect(isolate.breakpoints!.length, 1);

            await event; // Wait for breakpoint events.
          },
        )
        // We are at the breakpoint on LINE_A.
        .stoppedAtLine('LINE_A')
        // Stepping
        .stepOver()
        // We are now at line LINE_B.
        .stoppedAtLine('LINE_B')
        // Remove breakpoint
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          try {
            await service.streamListen(EventStreams.kDebug);
          } catch (_) {}

          final isolateId = isolateRef.id!;
          var isolate = await service.getIsolate(isolateId);

          // Set up a listener to wait for breakpoint events.
          final event = waitForEvent(service, EventKind.kBreakpointRemoved);

          expect(isolate.breakpoints!.length, 1);
          final bpt = isolate.breakpoints!.first;
          await service.removeBreakpoint(isolateId, bpt.id!);
          await event;

          isolate = await service.getIsolate(isolateId);
          expect(isolate.breakpoints!.length, 0);
        })
        // Resume
        .resumeIsolate()
        // Add breakpoint at function entry
        .addCustomTestWithParser(
          (service, isolateRef, scriptParser) async {
            try {
              await service.streamListen(EventStreams.kDebug);
            } catch (_) {}

            // Set up a listener to wait for breakpoint events.
            final event = waitForEvent(service, EventKind.kPauseBreakpoint);

            final isolateId = isolateRef.id!;
            var isolate = await service.getIsolate(isolateId);
            final rootLib = await service.getObject(
                isolateId,
                isolate.libraries!
                    .firstWhere((l) => l.uri!.contains('debugging_lib'))
                    .id!) as Library;

            // Find a specific function.
            final function = rootLib.functions!.firstWhere(
              (f) => f.name == 'periodicTask',
            );

            // Add the breakpoint at function entry
            final bpt = await service.addBreakpointAtEntry(
              isolateId,
              function.id!,
            );

            final script = await service.getObject(
              isolateId,
              bpt.location!.script!.id!,
            ) as Script;
            expect(script.uri, endsWith('debugging_lib.dart'));
            final lineC = scriptParser.lineForTag('LINE_C');
            expect(
              script.getLineNumberFromTokenPos(bpt.location!.tokenPos),
              lineC,
            );

            isolate = await service.getIsolate(isolateId);
            expect(isolate.breakpoints!.length, 1);

            await event; // Wait for breakpoint events.
          },
        )
        // We are now at line LINE_C, the entrypoint for periodicTask.
        .stoppedAtLine('LINE_C')
        .run(testeeMain: testee_lib.main);
