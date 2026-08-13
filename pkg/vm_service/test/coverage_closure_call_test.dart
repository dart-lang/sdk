// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'coverage_closure_call_lib.dart' as testee_lib;

void main(List<String> args) {
  IsolateTestHarness(
    'coverage_closure_call_lib.dart',
    args,
  )
      .hasStoppedAtBreakpoint()
      .addCustomTest(
        (VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final stack = await service.getStack(isolateId);

          // Make sure we are in the right place.
          final frames = stack.frames!;
          expect(frames.length, greaterThanOrEqualTo(1));
          expect(frames[0].function!.name, 'testFunction');

          final rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere(
                      (l) => l.uri!.contains('coverage_closure_call_lib'))
                  .id!) as Library;
          final funcRef =
              rootLib.functions!.singleWhere((f) => f.name == 'leafFunction');
          final func = await service.getObject(isolateId, funcRef.id!) as Func;

          final expectedRange = {
            'scriptIndex': 0,
            'startPos': 277,
            'endPos': 351,
            'compiled': true,
            'coverage': {
              'hits': [],
              'misses': [277, 321],
            },
          };

          final location = func.location!;
          final report = await service.getSourceReport(
            isolateId,
            [SourceReportKind.kCoverage],
            scriptId: location.script!.id!,
            tokenPos: location.tokenPos,
            endTokenPos: location.endTokenPos,
            forceCompile: true,
          );

          final ranges = report.ranges!;
          final scripts = report.scripts!;
          expect(ranges.length, 1);
          expect(ranges[0].toJson(), expectedRange);
          expect(scripts.length, 1);
          expect(scripts[0].uri, endsWith('coverage_closure_call_lib.dart'));
        },
      )
      .resumeIsolate()
      .hasStoppedAtBreakpoint()
      .addCustomTest(
        (VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final stack = await service.getStack(isolateId);

          // Make sure we are in the right place.
          final frames = stack.frames!;
          expect(frames.length, greaterThanOrEqualTo(1));
          expect(frames[0].function!.name, 'testFunction');

          final rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere(
                      (l) => l.uri!.contains('coverage_closure_call_lib'))
                  .id!) as Library;
          final funcRef =
              rootLib.functions!.singleWhere((f) => f.name == 'leafFunction');
          final func = await service.getObject(isolateId, funcRef.id!) as Func;

          final expectedRange = {
            'scriptIndex': 0,
            'startPos': 277,
            'endPos': 351,
            'compiled': true,
            'coverage': {
              'hits': [277, 321],
              'misses': [],
            },
          };

          final location = func.location!;
          final report = await service.getSourceReport(
            isolateId,
            [SourceReportKind.kCoverage],
            scriptId: location.script!.id!,
            tokenPos: location.tokenPos,
            endTokenPos: location.endTokenPos,
            forceCompile: true,
          );

          final ranges = report.ranges!;
          final scripts = report.scripts!;
          expect(ranges.length, 1);
          expect(ranges[0].toJson(), expectedRange);
          expect(scripts.length, 1);
          expect(scripts[0].uri, endsWith('coverage_closure_call_lib.dart'));
        },
      )
      .run(testeeMain: testee_lib.main);
}
