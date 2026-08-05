// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=dot-shorthands
// @dart = 3.10

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'dot_shorthands_lib.dart' as testee_lib;

void main([
  args = const <String>[],
]) => IsolateTestHarness('dot_shorthands_lib.dart', args)
    .hasStoppedAtBreakpoint()
    // Test interaction of expression evaluation with dot shorthands.
    .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      InstanceRef response =
          await service.evaluateInFrame(isolateId, 0, '(c = .two).value')
              as InstanceRef;
      expect(response.valueAsString, '2');

      response =
          await service.evaluateInFrame(isolateId, 0, '(c = .three).value')
              as InstanceRef;
      expect(response.valueAsString, '3');

      response =
          await service.evaluateInFrame(isolateId, 0, '(c = .four()).value')
              as InstanceRef;
      expect(response.valueAsString, '4');
    })
    // Test interaction of breakpoints with dot shorthands.
    .addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final lib =
          (await service.getObject(
                isolateId,
                isolate.libraries!
                    .firstWhere((l) => l.uri!.contains('dot_shorthands_lib'))
                    .id!,
              ))
              as Library;
      final scriptId = lib.scripts!.first.id!;

      Breakpoint breakpoint = await service.addBreakpoint(
        isolateId,
        scriptId,
        parser.lineForTag('LINE_D'),
      );
      var (_, (line, column)) = await breakpoint.getLocation(
        service,
        isolateRef,
      );
      expect(breakpoint.enabled, true);
      expect(line, parser.lineForTag('LINE_D'));
      expect(column, 7); // on '.'

      breakpoint = await service.addBreakpoint(
        isolateId,
        scriptId,
        parser.lineForTag('LINE_E'),
      );
      (_, (line, column)) = await breakpoint.getLocation(service, isolateRef);
      expect(breakpoint.enabled, true);
      expect(line, parser.lineForTag('LINE_E'));
      expect(column, 7); // on '.'
      await service.removeBreakpoint(isolateId, breakpoint.id!);

      breakpoint = await service.addBreakpoint(
        isolateId,
        scriptId,
        parser.lineForTag('LINE_F'),
      );
      (_, (line, column)) = await breakpoint.getLocation(service, isolateRef);
      expect(breakpoint.enabled, true);
      expect(line, parser.lineForTag('LINE_F'));
      expect(column, 7); // on '.'
      await service.removeBreakpoint(isolateId, breakpoint.id!);
    })
    // Test interaction of single-stepping with dot shorthands.
    .runStepIntoThroughProgramRecordingStops()
    .checkRecordedStops()
    .run(testeeMain: testee_lib.main, pauseOnExit: true);
