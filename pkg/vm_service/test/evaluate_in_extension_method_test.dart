// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

extension Foo on String {
  int parseInt(int x) {
    debugger();
    return foo();
  }

  int foo() => 42;
}

void testFunction() {
  print("10".parseInt(21));
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'x',
      '21',
      kind: InstanceKind.kInt,
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'this',
      '10',
      kind: InstanceKind.kString,
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'foo()',
      '42',
      kind: InstanceKind.kInt,
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'foo() + x',
      '63',
      kind: InstanceKind.kInt,
    );
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'foo() + x + int.parse(this)',
      '73',
      kind: InstanceKind.kInt,
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_in_extension_method_test.dart',
      testeeConcurrent: testFunction,
    );
