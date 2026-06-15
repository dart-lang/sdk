// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'inbound_references_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('inbound_references_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('inbound_references_lib'))
            .id!,
      ) as Library;
      final fieldRef = rootLib.variables!.where((v) => v.name == 'e').single;
      final field = await service.getObject(isolateId, fieldRef.id!) as Field;
      final e = field.staticValue! as InstanceRef;
      final response = await service.getInboundReferences(
        isolateId,
        e.id!,
        100,
      );
      final references = response.references!;

      void hasReferenceSuchThat(bool Function(InboundReference) predicate) {
        expect(references.any(predicate), isTrue);
      }

      // Assert inst is referenced by at least n, array, and the top-level
      // field e.
      hasReferenceSuchThat(
        (r) =>
            r.parentField != null &&
            r.parentField!.name == 'edge' &&
            r.source is InstanceRef &&
            (r.source as InstanceRef).classRef!.name == 'Node',
      );
      hasReferenceSuchThat(
        (r) =>
            r.parentListIndex == 1 &&
            r.source is InstanceRef &&
            (r.source as InstanceRef).kind == InstanceKind.kList,
      );
      hasReferenceSuchThat(
        (r) => r.source is FieldRef && (r.source as FieldRef).name == 'e',
      );
    }).run(testeeMain: testee_lib.main);
