// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://dartbug.com/52430.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class C {
  static int staticField = 12;
  int instanceField = 34;

  static void staticMethod() {
    ((int x) {
      debugger();
    })(56);
  }

  void instanceMethod() {
    ((int y) {
      debugger();
    })(78);
  }
}

testMain() {
  C c = C();
  C.staticMethod();
  c.instanceMethod();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(21),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final xRef =
        await service.evaluateInFrame(isolateId, 0, 'x') as InstanceRef;
    expect(xRef.valueAsString, '56');

    InstanceRef staticFieldRef = await service.evaluateInFrame(
        isolateId, 0, 'staticField += 1') as InstanceRef;
    expect(staticFieldRef.valueAsString, '13');
    staticFieldRef = await service.evaluateInFrame(isolateId, 0, 'staticField')
        as InstanceRef;
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
  },
  resumeIsolate,
  stoppedAtLine(27),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final yRef =
        await service.evaluateInFrame(isolateId, 0, 'y') as InstanceRef;
    expect(yRef.valueAsString, '78');

    InstanceRef staticFieldRef = await service.evaluateInFrame(
        isolateId, 0, 'staticField += 1') as InstanceRef;
    expect(staticFieldRef.valueAsString, '14');
    staticFieldRef = await service.evaluateInFrame(isolateId, 0, 'staticField')
        as InstanceRef;
    expect(staticFieldRef.valueAsString, '14');

    InstanceRef instanceFieldRef = await service.evaluateInFrame(
        isolateId, 0, 'instanceField += 1') as InstanceRef;
    expect(instanceFieldRef.valueAsString, '35');
    instanceFieldRef = await service.evaluateInFrame(
        isolateId, 0, 'instanceField') as InstanceRef;
    expect(instanceFieldRef.valueAsString, '35');
  }
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, 'evaluate_inside_closures_test.dart',
        testeeConcurrent: testMain);
