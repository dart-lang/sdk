// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'contexts_lib.dart' as testee_lib;

void main(List<String> args) => IsolateTestHarness(
      'contexts_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) => l.uri!.contains('contexts_lib'))
              .id!) as Library;
      final fieldRef =
          rootLib.variables!.singleWhere((v) => v.name == 'cleanBlock');
      final field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final block = await service.getObject(
        isolateId,
        field.staticValue.id!,
      ) as Instance;

      expect(block.closureFunction, isNotNull);
      expect(block.closureContext, isNull);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) => l.uri!.contains('contexts_lib'))
              .id!) as Library;
      final fieldRef =
          rootLib.variables!.singleWhere((v) => v.name == 'copyingBlock');
      final field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final block = await service.getObject(
        isolateId,
        field.staticValue.id!,
      ) as Instance;
      expect(block.closureFunction, isNotNull);
      expect(block.closureContext, isNotNull);

      final closureContext = block.closureContext!;
      expect(closureContext.length, 1);

      final ctxt =
          await service.getObject(isolateId, closureContext.id!) as Context;
      final value = ctxt.variables!.single.value as InstanceRef;
      expect(value.kind, InstanceKind.kString);
      expect(value.valueAsString, 'I could be copied into the block');
      expect(ctxt.parent, isNull);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) => l.uri!.contains('contexts_lib'))
              .id!) as Library;
      final fieldRef =
          rootLib.variables!.singleWhere((v) => v.name == 'fullBlock');
      final field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final block = await service.getObject(
        isolateId,
        field.staticValue.id!,
      ) as Instance;

      expect(block.closureFunction, isNotNull);
      expect(block.closureContext, isNotNull);

      final closureContext = block.closureContext!;
      expect(block.closureContext!.length, 1);

      final ctxt =
          await service.getObject(isolateId, closureContext.id!) as Context;
      final value = ctxt.variables!.single.value as InstanceRef;
      expect(value.kind, InstanceKind.kInt);
      expect(value.valueAsString, '43');
      expect(ctxt.parent, isNull);
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
          isolateId,
          isolate.libraries!
              .firstWhere((l) => l.uri!.contains('contexts_lib'))
              .id!) as Library;
      final fieldRef =
          rootLib.variables!.singleWhere((v) => v.name == 'fullBlockWithChain');
      final field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final block = await service.getObject(
        isolateId,
        field.staticValue.id!,
      ) as Instance;

      expect(block.closureFunction, isNotNull);
      expect(block.closureContext, isNotNull);

      final closureContext = block.closureContext!;
      expect(block.closureContext!.length, 1);

      final ctxt =
          await service.getObject(isolateId, closureContext.id!) as Context;
      final value = ctxt.variables!.single.value as InstanceRef;
      expect(value.kind, InstanceKind.kInt);
      expect(value.valueAsString, '4201');

      final parent = ctxt.parent!;
      expect(parent.length, 1);

      final outerCtxt =
          await service.getObject(isolateId, parent.id!) as Context;

      final outerValue = outerCtxt.variables!.single.value as InstanceRef;
      expect(outerValue.kind, InstanceKind.kInt);
      expect(outerValue.valueAsString, '421');
      expect(outerCtxt.parent, isNull);
    }).run(testeeMain: testee_lib.main);
