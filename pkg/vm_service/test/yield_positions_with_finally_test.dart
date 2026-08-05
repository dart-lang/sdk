// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'yield_positions_with_finally_lib.dart' as testee_lib;

Future<void> Function(VmService, IsolateRef, TestScriptParser)
    _expectSecondFrameFromTheTopToBeAt(
  String lineTag,
) {
  return (
    VmService service,
    IsolateRef isolateRef,
    TestScriptParser parser,
  ) async {
    final line = parser.lineForTag(lineTag);
    final lineG = parser.lineForTag('LINE_G');
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    final frames = stack.asyncCausalFrames!;
    expect(frames.length, greaterThanOrEqualTo(3));

    // Check second top frame contains correct line number.
    expect(frames[0].kind, FrameKind.kRegular);
    final frame0Location = frames[0].location!;
    final script0 = await service.getObject(
      isolateId,
      frame0Location.script!.id!,
    ) as Script;
    expect(
      script0.getLineNumberFromTokenPos(frame0Location.tokenPos!),
      lineG,
    );
    expect(frames[1].kind, FrameKind.kAsyncSuspensionMarker);
    expect(frames[2].location, isNotNull);
    expect(frames[2].kind, FrameKind.kAsyncCausal);
    final frame2Location = frames[2].location!;
    final script2 = await service.getObject(
      isolateId,
      frame2Location.script!.id!,
    ) as Script;
    expect(
      script2.getLineNumberFromTokenPos(frames[2].location!.tokenPos!),
      line,
    );
  };
}

void main([args = const <String>[]]) {
  final harness =
      IsolateTestHarness('yield_positions_with_finally_lib.dart', args)
          .hasPausedAtStart()
          .setBreakpointAtLine('LINE_G')
          .resumeIsolate();

  for (final line in [
    'LINE_A',
    'LINE_B',
    'LINE_C',
    'LINE_D',
    'LINE_E',
    'LINE_F',
  ]) {
    harness
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_G')
        .addCustomTestWithParser(_expectSecondFrameFromTheTopToBeAt(line))
        .resumeIsolate();
  }

  harness
      .hasStoppedAtExit()
      .run(testeeMain: testee_lib.main, pauseOnStart: true, pauseOnExit: true);
}
