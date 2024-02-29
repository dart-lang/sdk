// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class Foo {
  @pragma('vm:entry-point')
  dynamic left;
  @pragma('vm:entry-point')
  dynamic right;
}

late Foo r;

late List lst;

Function deepEquality = const DeepCollectionEquality().equals;

void script() {
  // Create 3 instances of Foo, with out-degrees
  // 0 (for b), 1 (for a), and 2 (for staticFoo).
  r = Foo();
  final a = Foo();
  final b = Foo();
  r.left = a;
  r.right = b;
  a.left = b;

  lst = List.filled(2, null);
  lst[0] = lst; // Self-loop.
  // Larger than any other fixed-size list in a fresh heap.
  lst[1] = List.filled(1234569, null);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    // HeapSnapshotGraph serializes.
    final graph = await HeapSnapshotGraph.getSnapshot(service, isolate);
    _verifySerialization(graph);
  },
  (VmService service, IsolateRef isolate) async {
    // Snap shot serializes with opted out information.
    final graph = await HeapSnapshotGraph.getSnapshot(
      service,
      isolate,
      calculateReferrers: true,
      decodeExternalProperties: false,
      decodeIdentityHashCodes: false,
      decodeObjectData: false,
    );
    expect(graph.objects[10].data, isA<HeapSnapshotObjectNoData>());
    expect(graph.objects[10].identityHashCode, 0);
    expect(graph.externalProperties, isEmpty);
    expect(graph.objects[10].referrers, isNotNull);
    _verifySerialization(graph);
  },
  (VmService service, IsolateRef isolate) async {
    // Referrers are calculated by default.
    final snapshotGraph = await HeapSnapshotGraph.getSnapshot(service, isolate);
    expect(snapshotGraph.objects[10].referrers, isNotNull);
  },
  (VmService service, IsolateRef isolate) async {
    // Referrers are not calculated if opted out.
    final snapshotGraph = await HeapSnapshotGraph.getSnapshot(
      service,
      isolate,
      calculateReferrers: false,
    );
    final object = snapshotGraph.objects[10];
    expect(() => object.referrers, throwsStateError);
  },
  (VmService service, IsolateRef isolate) async {
    final snapshotGraph = await HeapSnapshotGraph.getSnapshot(service, isolate);

    expect(snapshotGraph.name, 'main');
    expect(snapshotGraph.flags, isNotNull);
    expect(snapshotGraph.objects, isNotNull);
    expect(snapshotGraph.objects, isNotEmpty);

    int actualShallowSize = 0;
    int actualRefCount = 0;
    for (final o in snapshotGraph.objects) {
      // -1 is the CID used by the sentinel.
      expect(o.classId >= -1, isTrue);
      expect(o.data, isNotNull);
      expect(o.references, isNotNull);
      actualShallowSize += o.shallowSize;
      actualRefCount += o.references.length;
    }

    // Some accounting differences in the VM result in the global shallow size
    // often being greater than the sum of the object shallow sizes.
    expect(snapshotGraph.shallowSize >= actualShallowSize, isTrue);
    expect(snapshotGraph.shallowSize <= snapshotGraph.capacity, isTrue);
    expect(snapshotGraph.referenceCount >= actualRefCount, isTrue);

    int actualExternalSize = 0;
    expect(snapshotGraph.externalProperties, isNotEmpty);
    for (var e in snapshotGraph.externalProperties) {
      actualExternalSize += e.externalSize;
      expect(e.object >= 0, isTrue);
      expect(e.name, isNotNull);
    }
    expect(snapshotGraph.externalSize, actualExternalSize);

    expect(snapshotGraph.classes, isNotEmpty);
    for (var c in snapshotGraph.classes) {
      expect(c.name, isNotNull);
      expect(c.libraryName, isNotNull);
      expect(c.libraryUri, isNotNull);
      expect(c.fields, isNotNull);
    }

    // We have the class "Foo".
    int foosFound = 0;
    int fooClassId = -1;
    for (int i = 0; i < snapshotGraph.classes.length; i++) {
      final HeapSnapshotClass c = snapshotGraph.classes[i];
      if (c.name == 'Foo' &&
          c.libraryUri.toString().endsWith('heap_snapshot_graph_test.dart')) {
        foosFound++;
        fooClassId = i;
      }
    }
    expect(foosFound, equals(1));

    // It knows about "Foo" objects.
    foosFound = 0;
    for (final o in snapshotGraph.objects) {
      if (o.classId == 0) continue;
      if (o.classId == fooClassId) {
        foosFound++;
      }
    }
    expect(foosFound, equals(3));

    // Check that we can get another snapshot.
    final snapshotGraph2 =
        await HeapSnapshotGraph.getSnapshot(service, isolate);
    expect(snapshotGraph2.name, 'main');
  },
];

void _verifySerialization(HeapSnapshotGraph graph) {
  final chunks = graph.toChunks();
  final graphCopy = HeapSnapshotGraph.fromChunks(chunks);

  expect(graphCopy.name, graph.name);
  expect(graphCopy.flags.bitLength, graph.flags.bitLength);
  expect(graphCopy.objects.length, graph.objects.length);
  expect(graphCopy.classes.length, graph.classes.length);
  expect(
    graphCopy.externalProperties.length,
    graph.externalProperties.length,
  );
  expect(graphCopy.externalSize, graph.externalSize);
  expect(graphCopy.shallowSize, graph.shallowSize);
  expect(graphCopy.capacity, graph.capacity);
  expect(graphCopy.referenceCount, graph.referenceCount);

  for (var i = 0; i < graph.objects.length; i++) {
    _verifyObjectsAreEqual(graph.objects[i], graphCopy.objects[i]);
  }

  for (var i = 0; i < graph.classes.length; i++) {
    _verifyClassesAreEqual(graph.classes[i], graphCopy.classes[i]);
  }
}

void _verifyObjectsAreEqual(HeapSnapshotObject a, HeapSnapshotObject b) {
  expect(a.classId, b.classId);
  expect(a.shallowSize, b.shallowSize);
  expect(a.data.runtimeType, b.data.runtimeType);
  expect(a.identityHashCode, b.identityHashCode);
  expect(deepEquality(a.references, b.references), true);
  expect(deepEquality(a.referrers, b.referrers), true);
}

void _verifyClassesAreEqual(HeapSnapshotClass a, HeapSnapshotClass b) {
  expect(a.name, b.name);
  expect(a.libraryName, b.libraryName);
  expect(a.libraryUri, b.libraryUri);
  expect(a.fields, hasLength(b.fields.length));
  for (var i = 0; i < a.fields.length; i++) {
    _verifyFieldsAreEqual(a.fields[i], b.fields[i]);
  }
}

void _verifyFieldsAreEqual(HeapSnapshotField a, HeapSnapshotField b) {
  expect(a.name, b.name);
  expect(a.index, b.index);
  expect(a.toString(), b.toString());
}

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'heap_snapshot_graph_test.dart',
      testeeBefore: script,
    );
