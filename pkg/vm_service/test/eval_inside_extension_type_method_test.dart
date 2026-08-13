// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'eval_inside_extension_type_method_lib.dart' as testee_lib;

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

void main([args = const <String>[]]) =>
    IsolateTestHarness('eval_inside_extension_type_method_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest(triggerEvaluation)
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
