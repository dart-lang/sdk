// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

dynamic escapedClosure;

testeeMain() {}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;

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
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_with_escaping_closure_test.dart',
      testeeBefore: testeeMain,
    );
