// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

@pragma("vm:entry-point") // Prevent obfuscation
class Node {
  // Make sure this field is not removed by the tree shaker.
  @pragma("vm:entry-point") // Prevent obfuscation
  var edge;
}

class Edge {}

@pragma("vm:entry-point") // Prevent obfuscation
var n, e, array;

void script() {
  n = Node();
  e = Edge();
  n.edge = e;
  array = List<dynamic>.filled(2, null);
  array[0] = n;
  array[1] = e;
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
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
    hasReferenceSuchThat((r) =>
        r.parentField != null &&
        r.parentField!.name == 'edge' &&
        r.source is InstanceRef &&
        (r.source as InstanceRef).classRef!.name == 'Node');
    hasReferenceSuchThat(
      (r) =>
          r.parentListIndex == 1 &&
          r.source is InstanceRef &&
          (r.source as InstanceRef).kind == InstanceKind.kList,
    );
    hasReferenceSuchThat(
      (r) => r.source is FieldRef && (r.source as FieldRef).name == 'e',
    );
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'inbound_references_test.dart',
      testeeBefore: script,
    );
