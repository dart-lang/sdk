// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

extension on String {
  String printAndReturnHello() {
    String response = "Hello from String '$this'";
    print(response);
    return response;
  }
}

void testFunction() {
  String x = "hello";
  String value = x.printAndReturnHello();
  debugger();
  print("value = $value");
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'x.printAndReturnHello()',
      "Hello from String 'hello'",
      kind: InstanceKind.kString,
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_type_with_extension_test.dart',
      testeeConcurrent: testFunction,
    );
