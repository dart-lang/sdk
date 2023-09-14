// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

class Foo {
  Foo();
  Foo.named();
}

class Generic<T> {
  Generic();
}

@pragma('vm:entry-point')
Function getNamedConstructorTearoff() => Foo.named;

@pragma('vm:entry-point')
Function getDefaultConstructorTearoff() => Foo.new;

@pragma('vm:entry-point')
Function getGenericConstructorTearoff() => Generic<int>.new;

Future<void> invokeConstructorTearoff(
  VmService service,
  IsolateRef isolateRef,
  String name,
  String expectedType,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib =
      await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
  final tearoff =
      await service.invoke(isolateId, rootLib.id!, name, []) as InstanceRef;
  final result =
      await service.invoke(isolateId, tearoff.id!, 'call', []) as InstanceRef;
  expect(result.classRef!.name, expectedType);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) => invokeConstructorTearoff(
        service,
        isolateRef,
        'getNamedConstructorTearoff',
        'Foo',
      ),
  (VmService service, IsolateRef isolateRef) => invokeConstructorTearoff(
        service,
        isolateRef,
        'getDefaultConstructorTearoff',
        'Foo',
      ),
  (VmService service, IsolateRef isolateRef) => invokeConstructorTearoff(
        service,
        isolateRef,
        'getGenericConstructorTearoff',
        'Generic',
      ),
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'constructor_tear_off_test.dart',
    );
