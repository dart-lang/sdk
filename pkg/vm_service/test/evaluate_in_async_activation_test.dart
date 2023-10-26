// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 19;
const LINE_B = LINE_A + 2;

testFunction() async {
  var x = 3;
  var y = 4;
  debugger();
  var z = await new Future(() => x + y);
  debugger();
  return z;
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(service, isolateId, 'x', '3');
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(service, isolateId, 'z', '7');
  },
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_in_async_activation_test.dart',
      testeeConcurrent: testFunction,
    );
