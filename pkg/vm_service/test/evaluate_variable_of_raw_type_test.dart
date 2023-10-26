// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  List<dynamic> v = <dynamic>[1, 2, '3'];
  debugger();
  print("v = $v");
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'v.length',
      '3',
      kind: InstanceKind.kInt,
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_variable_of_raw_type_test.dart',
      testeeConcurrent: testFunction,
    );
