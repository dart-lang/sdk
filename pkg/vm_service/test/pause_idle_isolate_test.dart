// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'pause_idle_isolate_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('pause_idle_isolate_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      // Wait for the isolate to become idle.  We detect this by querying
      // the stack until it becomes empty.
      int frameCount;
      do {
        final stack = await service.getStack(isolateId);
        frameCount = stack.frames!.length;
        print('Frames: $frameCount');
        await Future.delayed(const Duration(milliseconds: 10));
      } while (frameCount > 0);
      print('Isolate is idle.');
      final isolate = await service.getIsolate(isolateId);
      expect(isolate.pauseEvent!.kind, EventKind.kResume);

      // Make sure that the isolate receives an interrupt even when it is
      // idle. (https://github.com/dart-lang/sdk/issues/24349)
      final interruptFuture = hasPausedFor(
        service,
        isolate,
        EventKind.kPauseInterrupted,
      );
      print('Pausing...');
      await service.pause(isolateId);
      await interruptFuture;
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: ['--trace-service', '--trace-service-verbose'],
    );
