// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_with_escaping_closure_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_with_escaping_closure_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere(
              (l) => l.uri!.contains('evaluate_with_escaping_closure_lib'))
          .id!;

      final result = await service.evaluate(
        isolateId,
        rootLibId,
        'escapedClosure = (x, y) => x + y',
      ) as InstanceRef;
      expect(result.classRef!.name, startsWith('_Closure'));

      for (var i = 0; i < 100; i++) {
        await evaluateAndExpect(
          service,
          isolateId,
          rootLibId,
          'escapedClosure(3, 4)',
          '7',
        );
      }
    }).run(testeeMain: testee_lib.main);
