// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    const test = '''(){ 
          var k = () { return Future.value(3); };
          var w = () async { return await k(); };
          return w();
        }()''';
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;
    final result = await service.evaluate(
      isolateId,
      rootLibId,
      test,
    ) as InstanceRef;
    expect(result.kind, InstanceKind.kPlainInstance);
    expect(result.classRef!.name, '_Future');
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_async_closure_test.dart',
    );
