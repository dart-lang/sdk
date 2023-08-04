// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final abcString = "abc";

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final evalResult = await service.evaluate(
        isolateId, isolate.rootLib!.id!, 'abcString') as InstanceRef;
    final getObjectIdResult = await Service.getObjectId(abcString)!;
    final objectFromEval =
        await service.getObject(isolateId, evalResult.id!) as Instance;
    final objectFromGetObjectId =
        await service.getObject(isolateId, getObjectIdResult) as Instance;
    expect(objectFromEval.identityHashCode,
        objectFromGetObjectId.identityHashCode);
    expect(objectFromEval.valueAsString, objectFromGetObjectId.valueAsString);
  },
];

main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'developer_service_get_object_id_test.dart',
    );
