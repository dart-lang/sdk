// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'positive_token_pos_lib.dart' as testee_lib;

const LINE_B_COL = 3;
const LINE_C_COL = 1;

void main([args = const <String>[]]) => IsolateTestHarness(
      'positive_token_pos_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .stepInto()
        .addCustomTestWithParser(
      (VmService service, IsolateRef isolateRef, scriptParser) async {
        final isolateId = isolateRef.id!;
        final stack = await service.getStack(isolateId);
        final frames = stack.frames!;
        expect(frames.length, greaterThan(2));

        final lineC = scriptParser.lineForTag('LINE_C');
        final lineB = scriptParser.lineForTag('LINE_B');

        // We used to return a negative token position for this frame.
        // See issue #27128.
        var frame = frames[0];
        expect(frame.function!.name, 'helper');
        expect(frame.location!.line, lineC + 1);
        expect(frame.location!.column, LINE_C_COL);

        frame = frames[1];
        expect(frame.function!.name, 'testMain');
        expect(frame.location!.line, lineB);
        expect(frame.location!.column, LINE_B_COL);
      },
    ).run(testeeMain: testee_lib.main);
