// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'async_scope_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

Future<void> checkAsyncVarDescriptors(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final stack = await service.getStack(isolateId);
  expect(stack.frames!.length, greaterThanOrEqualTo(1));
  final frame = stack.frames![0];
  final vars = frame.vars!.map((v) => v.name).join(' ');
  expect(vars, 'param1 local1'); // no :async_op et al
}

Future<void> checkAsyncStarVarDescriptors(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final stack = await service.getStack(isolateId);
  expect(stack.frames!.length, greaterThanOrEqualTo(1));
  final frame = stack.frames![0];
  final vars = frame.vars!.map((v) => v.name).join(' ');
  expect(vars, 'param2 local2'); // no :async_op et al
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('async_scope_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .setBreakpointAtLine('LINE_A')
        .setBreakpointAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(checkAsyncVarDescriptors)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(checkAsyncStarVarDescriptors)
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
