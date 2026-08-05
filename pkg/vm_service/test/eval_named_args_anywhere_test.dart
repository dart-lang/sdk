// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'eval_named_args_anywhere_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('eval_named_args_anywhere_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);

      final rootLibId = isolate.libraries!
          .firstWhere((l) => l.uri!.contains('eval_named_args_anywhere_lib'))
          .id!;

      // Evaluate top-level function
      var result = await service.evaluate(
        isolateId,
        rootLibId,
        'foo(b: 10, 50)',
      ) as InstanceRef;
      expect(result.valueAsString, '40');

      // Evaluate class instance method
      result = await service.evaluate(
        isolateId,
        rootLibId,
        '_MyClass().foo(b: 10, 50)',
      ) as InstanceRef;
      expect(result.valueAsString, '40');

      // Evaluate static method
      result = await service.evaluate(
        isolateId,
        rootLibId,
        '_MyClass.baz(b: 10, 50)',
      ) as InstanceRef;
      expect(result.valueAsString, '40');
    }).run(testeeMain: testee_lib.main);
