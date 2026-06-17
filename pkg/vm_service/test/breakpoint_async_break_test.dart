// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'breakpoint_async_break_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_async_break_lib.dart', args)
        .hasPausedAtStart()
        .addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final line = parser.lineForTag('LINE_A');
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) => l.uri!.contains('breakpoint_async_break_lib'))
              .id!) as Library;
      final scriptId = rootLib.scripts![0].id!;

      final bpt = await service.addBreakpoint(isolateId, scriptId, line);
      expect(bpt.breakpointNumber, 1);
      expect(bpt.resolved, isTrue);
      expect(await bpt.location!.line, line);
      expect(await bpt.location!.column, 7);

      await service.resume(isolateId);
      await hasStoppedAtBreakpoint(service, isolate);

      // Remove the breakpoints.
      expect(
        (await service.removeBreakpoint(isolateId, bpt.id!)).type,
        'Success',
      );
    }).run(testeeMain: testee_lib.main, pauseOnStart: true);
