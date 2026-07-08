// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'eval_regression_flutter20255_lib.dart' as testee_lib;

Future triggerEvaluation(VmService service, IsolateRef isolateRef) async {
  final Stack stack = await service.getStack(isolateRef.id!);

  // Make sure we are in the right place.
  expect(stack.frames!.length, greaterThanOrEqualTo(2));
  expect(stack.frames![0].function!.name, 'foo');
  expect(stack.frames![0].function!.owner.name, 'Sub');

  // Trigger an evaluation, which will create a subclass of Base<T>.
  final dynamic result = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'this.field + " world \$T"',
  );
  expect(result.valueAsString, 'a world double');

  // Trigger an optimization of a type testing stub (and usage of it).
  final dynamic result2 = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'triggerTypeTestingStubGeneration()',
  );
  expect(result2.valueAsString, 'tts-generated');
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('eval_regression_flutter20255_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest(triggerEvaluation)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest(triggerEvaluation)
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
