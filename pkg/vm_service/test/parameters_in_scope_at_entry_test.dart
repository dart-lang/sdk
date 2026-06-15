// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'parameters_in_scope_at_entry_lib.dart' as testee_lib;

Future<void> testFooParam(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final stack = await service.getStack(isolateId);
  expect(stack.frames!, isNotEmpty);
  final top = stack.frames!.first;
  expect(top.function!.name, 'foo');
  expect(top.vars!.length, equals(1));
  final param = top.vars![0];
  expect(param.name, 'param');
  expect(param.value.valueAsString, 'in-scope');
}

Future<void> testClosureParam(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final stack = await service.getStack(isolateId);
  expect(stack.frames!, isNotEmpty);
  final top = stack.frames!.first;
  expect(top.function!.name, 'theClosureFunction');
  expect(top.vars!.length, equals(1));
  final param = top.vars![0];
  expect(param.name, 'param');
  expect(param.value.valueAsString, 'in-scope');
}

void main([args = const <String>[]]) {
  IsolateTestHarness(
    'parameters_in_scope_at_entry_lib.dart',
    args,
  )
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_A')
      .stepOver()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_B')
      .stepInto()
      .hasStoppedAtBreakpoint()
      .addCustomTest(testFooParam)
      .resumeIsolate()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_C')
      .stepOver()
      .hasStoppedAtBreakpoint()
      .stoppedAtLine('LINE_D')
      .stepInto()
      .hasStoppedAtBreakpoint()
      .addCustomTest(testClosureParam)
      .resumeIsolate()
      .run(testeeMain: testee_lib.main);
}
