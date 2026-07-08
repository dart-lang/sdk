// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_inside_closures_lib.dart' as testee_lib;

Future<void> testEvaluationInStaticMethod(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;

  final xRef = await service.evaluateInFrame(isolateId, 0, 'x') as InstanceRef;
  expect(xRef.valueAsString, '56');

  InstanceRef staticFieldRef = await service.evaluateInFrame(
    isolateId,
    0,
    'staticField += 1',
  ) as InstanceRef;
  expect(staticFieldRef.valueAsString, '13');
  staticFieldRef =
      await service.evaluateInFrame(isolateId, 0, 'staticField') as InstanceRef;
  expect(staticFieldRef.valueAsString, '13');

  // Evaluating 'instanceField' should fail since we are paused in the context
  // of a static method.
  try {
    await service.evaluateInFrame(isolateId, 0, 'instanceField');
    fail('Expected RPCError');
  } catch (e) {
    final rpcError = e as RPCError;
    expect(rpcError.code, RPCErrorKind.kExpressionCompilationError.code);
  }
}

Future<void> testEvaluationInInstanceMethod(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;

  final yRef = await service.evaluateInFrame(isolateId, 0, 'y') as InstanceRef;
  expect(yRef.valueAsString, '78');

  InstanceRef staticFieldRef = await service.evaluateInFrame(
    isolateId,
    0,
    'staticField += 1',
  ) as InstanceRef;
  expect(staticFieldRef.valueAsString, '14');
  staticFieldRef =
      await service.evaluateInFrame(isolateId, 0, 'staticField') as InstanceRef;
  expect(staticFieldRef.valueAsString, '14');

  InstanceRef instanceFieldRef = await service.evaluateInFrame(
    isolateId,
    0,
    'instanceField += 1',
  ) as InstanceRef;
  expect(instanceFieldRef.valueAsString, '35');
  instanceFieldRef = await service.evaluateInFrame(
    isolateId,
    0,
    'instanceField',
  ) as InstanceRef;
  expect(instanceFieldRef.valueAsString, '35');
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'evaluate_inside_closures_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(testEvaluationInStaticMethod)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(testEvaluationInInstanceMethod)
        .run(testeeMain: testee_lib.main);
