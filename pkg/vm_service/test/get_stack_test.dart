// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_stack_lib.dart' as testee_lib;

void expectFrame(
  frame,
  kindExpectation,
  codeNameExpectation,
) {
  expect(frame.kind, kindExpectation);
  expect(frame.code?.name, codeNameExpectation);
}

void expectFrames(frames, expectKindAndCodeName) {
  for (int i = 0; i < expectKindAndCodeName.length; i++) {
    expectFrame(
      frames[i],
      expectKindAndCodeName[i][0],
      expectKindAndCodeName[i][1],
    );
  }
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_stack_lib.dart',
      args,
    )
        // Before the first await.
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // At LINE_A we're still running sync. so no asyncCausalFrames.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final result = await service.getStack(isolateRef.id!);

          expect(result.frames, hasLength(19));
          expect(result.asyncCausalFrames, isNull);

          expectFrames(result.frames, [
            [equals('Regular'), endsWith(' func10')],
            [equals('Regular'), endsWith(' func9')],
            [equals('Regular'), endsWith(' func8')],
            [equals('Regular'), endsWith(' func7')],
            [equals('Regular'), endsWith(' func6')],
            [equals('Regular'), endsWith(' func5')],
            [equals('Regular'), endsWith(' func4')],
            [equals('Regular'), endsWith(' func3')],
            [equals('Regular'), endsWith(' func2')],
            [equals('Regular'), endsWith(' func1')],
            [equals('Regular'), endsWith(' testMain')],
          ]);
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_1')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        // After resuming the continuation - i.e. running async.
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final result = await service.getStack(isolateRef.id!);

          expect(result.frames, hasLength(6));
          expect(result.asyncCausalFrames, hasLength(26));

          expectFrames(result.frames!, [
            [equals('Regular'), endsWith(' func10')],
            [equals('Regular'), anything], // Internal mech. ..
            [equals('Regular'), anything],
            [equals('Regular'), anything],
            [equals('Regular'), anything],
            [equals('Regular'), endsWith(' _RawReceivePort._handleMessage')],
          ]);

          expectFrames(result.asyncCausalFrames, [
            [equals('Regular'), endsWith(' func10')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func9')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func8')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func7')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func6')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func5')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func4')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func3')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func2')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' func1')],
            [equals('AsyncSuspensionMarker'), isNull],
            [equals('AsyncCausal'), endsWith(' testMain')],
            [equals('AsyncSuspensionMarker'), isNull],
          ]);
        })
        .run(testeeMain: testee_lib.main);
