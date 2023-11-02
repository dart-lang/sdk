// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 18;
const LINE_B = LINE_A + 3;
const LINE_C = LINE_B + 6;
const LINE_D = LINE_C + 8;
const LINE_E = LINE_D + 4;

topLevel<S>() {
  debugger();

  void inner1<TBool, TString, TDouble, TInt>(TInt x) {
    debugger();
  }

  inner1<bool, String, double, int>(3);

  void inner2() {
    debugger();
  }

  inner2();
}

class A {
  foo<T, S>() {
    debugger();
  }

  bar<T>(T t) {
    debugger();
  }
}

void testMain() {
  topLevel<String>();
  (A()).foo<int, bool>();
  (A()).bar<dynamic>(42);
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
        service, isolateId, 'S.toString()', 'String');
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'TBool.toString()',
      'bool',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'S.toString()',
      'String',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'TString.toString()',
      'String',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'TDouble.toString()',
      'double',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'TInt.toString()',
      'int',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'x',
      '3',
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'S.toString()',
      'String',
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'T.toString()',
      'int',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'S.toString()',
      'bool',
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'T.toString()',
      'dynamic',
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      't',
      '42',
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_function_type_parameters_test.dart',
      testeeConcurrent: testMain,
    );
