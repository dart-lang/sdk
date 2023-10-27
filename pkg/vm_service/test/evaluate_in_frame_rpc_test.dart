// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void method(int value, _) {
  debugger();
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      method(10000, 50);
    }
  }
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Evaluate against library, class, and instance.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(service, isolateId, 'value', '10000');
    await evaluateInFrameAndExpect(service, isolateId, '_', '50');
    await evaluateInFrameAndExpect(service, isolateId, 'value + _', '10050');
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'i',
      '100000000',
      topFrame: 1,
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_in_frame_rpc_test.dart',
      testeeConcurrent: testFunction,
    );
