// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'constructor_tear_off_lib.dart' as testee_lib;

Future<void> invokeConstructorTearoff(
  VmService service,
  IsolateRef isolateRef,
  String name,
  String expectedType,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib = await service.getObject(
      isolateId,
      isolate.libraries!
          .firstWhere((l) => l.uri!.contains('constructor_tear_off_lib'))
          .id!) as Library;
  final tearoff =
      await service.invoke(isolateId, rootLib.id!, name, []) as InstanceRef;
  final result =
      await service.invoke(isolateId, tearoff.id!, 'call', []) as InstanceRef;
  expect(result.classRef!.name, expectedType);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('constructor_tear_off_lib.dart', args)
        .addCustomTest(
          (VmService service, IsolateRef isolateRef) =>
              invokeConstructorTearoff(
            service,
            isolateRef,
            'getNamedConstructorTearoff',
            'Foo',
          ),
        )
        .addCustomTest(
          (VmService service, IsolateRef isolateRef) =>
              invokeConstructorTearoff(
            service,
            isolateRef,
            'getDefaultConstructorTearoff',
            'Foo',
          ),
        )
        .addCustomTest(
          (VmService service, IsolateRef isolateRef) =>
              invokeConstructorTearoff(
            service,
            isolateRef,
            'getGenericConstructorTearoff',
            'Generic',
          ),
        )
        .run(testeeMain: testee_lib.main);
