// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';

void method(int value, _) {
  debugger();
}

void testeeMain() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      method(10000, 50);
    }
  }
}

final evaluateInFrameRpcTests = <IsolateTest>[
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
