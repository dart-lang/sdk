// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_stack_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_stack_rpc_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Get stack
        .addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final lineA = parser.lineForTag('LINE_A');
      final isolateId = isolateRef.id!;
      final stack = await service.getStack(isolateId);

      // Sanity check.
      final frames = stack.frames!;
      expect(frames.length, greaterThanOrEqualTo(1));
      final scriptId = frames[0].location!.script!.id!;
      final script = await service.getObject(isolateId, scriptId) as Script;
      expect(
        script.getLineNumberFromTokenPos(frames[0].location!.tokenPos!),
        lineA,
      );

      // Iterate over frames.
      int frameDepth = 0;
      for (var frame in frames) {
        print('checking frame $frameDepth');
        expect(frame.index, equals(frameDepth++));
        expect(frame.code, isNotNull);
        expect(frame.function, isNotNull);
        expect(frame.location, isNotNull);
      }
    }).run(testeeMain: testee_lib.main);
