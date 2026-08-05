// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_retaining_path_rpc_lib.dart' as testee_lib;

Future<InstanceRef> invoke(String selector) async {
  final r = await rootService.invoke(
    isolateId,
    isolate.libraries!
        .firstWhere((l) => l.uri!.contains('get_retaining_path_rpc_lib'))
        .id!,
    selector,
    [],
  );
  if (r is InstanceRef) return r;
  throw Exception('Expected InstanceRef, got $r');
}

late final VmService rootService;
late final Isolate isolate;
late final String isolateId;

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_retaining_path_rpc_lib.dart',
      args,
    )
        // Initialization
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      isolateId = isolateRef.id!;
      rootService = service;
      isolate = await service.getIsolate(isolateId);
    })
        // simple path
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final obj = await invoke('getGlobalObject');
      final result = await service.getRetainingPath(isolateId, obj.id!, 100);
      expect(result.gcRootType, 'user global');
      expect(result.elements!.length, 2);
      expect((result.elements![1].value! as FieldRef).name, 'globalObject');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeTarget1');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      expect(result.gcRootType, 'user global');
      final elements = result.elements!;
      expect(elements.length, 3);
      expect(elements[1].parentField, 'x');
      expect((elements[2].value as FieldRef).name, 'globalObject');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeTarget2');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      expect(result.gcRootType, 'user global');
      final elements = result.elements!;
      expect(elements.length, 3);
      expect(elements[1].parentField, 'y');
      expect((elements[2].value as FieldRef).name, 'globalObject');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeTarget3');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      expect(result.gcRootType, 'user global');
      final elements = result.elements!;
      expect(elements.length, 3);
      expect(elements[1].parentListIndex, 12);
      expect((elements[2].value as FieldRef).name, 'globalList');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeTarget4');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      expect(result.gcRootType, 'user global');
      final elements = result.elements!;
      expect(elements.length, 3);
      expect((elements[1].parentMapKey as InstanceRef).valueAsString, 'key');
      expect((elements[2].value as FieldRef).name, 'globalMap1');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeTarget5');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      expect(result.gcRootType, 'user global');
      final elements = result.elements!;
      expect(elements.length, 3);
      expect(
        (elements[1].parentMapKey as InstanceRef).classRef!.name,
        '_TestClass',
      );
      expect((elements[2].value as FieldRef).name, 'globalMap2');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      // Regression test for https://github.com/dart-lang/sdk/issues/44016
      final target = await invoke('takeExpandoTarget');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      final elements = result.elements!;
      expect(elements.length, 5);
      expect(
        (elements[1].parentMapKey as InstanceRef).classRef!.name,
        '_TestClass',
      );
      expect(elements[2].parentListIndex, isNotNull);
      expect((elements[4].value as FieldRef).name, 'expando');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeWeakReachableTarget');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      expect(result.gcRootType, 'user global');
      final elements = result.elements!;
      expect(elements.length, 3);
      expect(elements[1].parentField, 'y');
      expect((elements[2].value as FieldRef).name, 'weakReachable');
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final target = await invoke('takeWeakUnreachableTarget');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      final elements = result.elements!;
      expect(elements.length, 0);
    }).run(testeeMain: testee_lib.main);
