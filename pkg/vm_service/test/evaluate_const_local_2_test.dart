// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  const String foo = 'hello from foo';
  final List<String> list = ['hello'];
  // ignore: avoid_function_literals_in_foreach_calls
  list.forEach((String input) {
    // This is inside of a local function.
    debugger();
    print(foo);
    print(list);
    print(input);
  });
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.evaluateInFrame(
      isolateRef.id!,
      0,
      'foo',
    ) as InstanceRef;
    expect(result.valueAsString, equals('hello from foo'));
    expect(result.kind, equals(InstanceKind.kString));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_const_local_1_test.dart',
      testeeConcurrent: testFunction,
    );
