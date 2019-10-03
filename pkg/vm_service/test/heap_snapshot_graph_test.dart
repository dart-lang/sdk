// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class Foo {
  dynamic left;
  dynamic right;
}

Foo r;

List lst;

void script() {
  // Create 3 instances of Foo, with out-degrees
  // 0 (for b), 1 (for a), and 2 (for staticFoo).
  r = Foo();
  var a = Foo();
  var b = Foo();
  r.left = a;
  r.right = b;
  a.left = b;

  lst = List(2);
  lst[0] = lst; // Self-loop.
  // Larger than any other fixed-size list in a fresh heap.
  lst[1] = List(1234569);
}

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolate) async {
    final snapshotGraph = await HeapSnapshotGraph.getSnapshot(service, isolate);
    expect(snapshotGraph.name, "main");
    expect(snapshotGraph.flags, isNotNull);
    expect(snapshotGraph.objects, isNotNull);
    expect(snapshotGraph.objects.length > 0, isTrue);

    int actualShallowSize = 0;
    int actualRefCount = 0;
    snapshotGraph.objects.forEach((HeapSnapshotObject o) {
      expect(o.classId >= 0, isTrue);
      expect(o.data, isNotNull);
      expect(o.references, isNotNull);
      actualShallowSize += o.shallowSize;
      actualRefCount += o.references.length;
    });

    // Some accounting differences in the VM result in the global shallow size
    // often being greater than the sum of the object shallow sizes.
    expect(snapshotGraph.shallowSize >= actualShallowSize, isTrue);
    expect(snapshotGraph.shallowSize <= snapshotGraph.capacity, isTrue);
    expect(snapshotGraph.referenceCount >= actualRefCount, isTrue);

    int actualExternalSize = 0;
    expect(snapshotGraph.externalProperties.length > 0, isTrue);
    snapshotGraph.externalProperties.forEach((HeapSnapshotExternalProperty e) {
      actualExternalSize += e.externalSize;
      expect(e.object >= 0, isTrue);
      expect(e.name, isNotNull);
    });
    expect(snapshotGraph.externalSize, actualExternalSize);

    expect(snapshotGraph.classes.length > 0, isTrue);
    snapshotGraph.classes.forEach((HeapSnapshotClass c) {
      expect(c.name, isNotNull);
      expect(c.libraryName, isNotNull);
      expect(c.libraryUri, isNotNull);
      expect(c.fields, isNotNull);
    });
  },
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, testeeBefore: script);
