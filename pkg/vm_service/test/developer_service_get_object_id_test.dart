// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'developer_service_get_object_id_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('developer_service_get_object_id_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final evalAbcStringResult = await service.evaluateInFrame(
        isolateId,
        0,
        'abcString',
      ) as InstanceRef;
      final getObjectIdResult = (await service.evaluateInFrame(
        isolateId,
        0,
        'getObjectIdResult',
      ) as InstanceRef)
          .valueAsString!;

      final objectFromEval = await service.getObject(
        isolateId,
        evalAbcStringResult.id!,
      ) as Instance;
      final objectFromGetObjectId =
          await service.getObject(isolateId, getObjectIdResult) as Instance;
      expect(
        objectFromEval.identityHashCode,
        objectFromGetObjectId.identityHashCode,
      );
      expect(
        objectFromEval.valueAsString,
        objectFromGetObjectId.valueAsString,
      );
    }).run(testeeMain: testee_lib.main);
