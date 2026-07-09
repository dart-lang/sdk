// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'weak_properties_lib.dart' as testee_lib;

Future<Instance> getFieldValue(
  VmService service,
  String isolateId,
  List<FieldRef> variables,
  String name,
) async {
  final fieldRef = variables.singleWhere((v) => v.name == name);
  final field = await service.getObject(
    isolateId,
    fieldRef.id!,
  ) as Field;
  return await service.getObject(
    isolateId,
    (field.staticValue as InstanceRef).id!,
  ) as Instance;
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('weak_properties_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final lib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('weak_properties_lib'))
            .id!,
      ) as Library;
      final variables = lib.variables!;

      final key = await getFieldValue(
        service,
        isolateId,
        variables,
        'key',
      );
      final value = await getFieldValue(
        service,
        isolateId,
        variables,
        'value',
      );
      final prop = await getFieldValue(
        service,
        isolateId,
        variables,
        'weakProperty',
      );

      expect(key.kind, isNot(InstanceKind.kWeakProperty));
      expect(value.kind, isNot(InstanceKind.kWeakProperty));

      // Object ids are not canonicalized, so we rely on the key and value
      // being the sole instances of their classes to test we got the objects
      // we expect.
      expect(prop.kind, InstanceKind.kWeakProperty);
      expect(prop.propertyKey, isNotNull);
      expect((prop.propertyKey! as InstanceRef).classRef, key.classRef);
      expect(prop.propertyValue, isNotNull);
      expect((prop.propertyValue! as InstanceRef).classRef, value.classRef);
    }).run(testeeMain: testee_lib.main);
