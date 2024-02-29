// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  final x = Foo(42);
  x.printFoo();
}

extension type Foo(int value) {
  void printFoo() {
    debugger();
    print("This foos value is '$value'");
  }
  int otherCall() {
    return value * 2;
  }
}

Future triggerEvaluation(VmService service, IsolateRef isolateRef) async {
  final Stack stack = await service.getStack(isolateRef.id!);

  // Make sure we are in the right place.
  expect(stack.frames!.length, greaterThanOrEqualTo(2));
  expect(stack.frames![0].function!.name, 'Foo.printFoo');

  final dynamic result = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'this.value',
  );
  expect(result.valueAsString, '42');

  final dynamic result2 = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'otherCall()',
  );
  expect(result2.valueAsString, '84');

  final dynamic result3 = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'this.value + value + otherCall()',
  );
  expect(result3.valueAsString, '168');
}

final testSteps = <IsolateTest>[
  hasStoppedAtBreakpoint,
  triggerEvaluation,
  resumeIsolate,
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      testSteps,
      'eval_inside_extension_type_method.dart',
      testeeConcurrent: testFunction,
    );
