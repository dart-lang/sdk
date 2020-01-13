// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/heap_snapshot.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/object_graph.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo {
  dynamic left;
  dynamic right;
}

Foo r;

List lst;

void script() {
  // Create 3 instances of Foo, with out-degrees
  // 0 (for b), 1 (for a), and 2 (for staticFoo).
  r = new Foo();
  var a = new Foo();
  var b = new Foo();
  r.left = a;
  r.right = b;
  a.left = b;

  lst = new List(2);
  lst[0] = lst; // Self-loop.
  // Larger than any other fixed-size list in a fresh heap.
  lst[1] = new List(1234569);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var raw = await isolate.fetchHeapSnapshot().last;
    HeapSnapshot snapshot = new HeapSnapshot();
    await snapshot.loadProgress(isolate, raw).last;
    var graph = snapshot.graph;

    Iterable<SnapshotObject> foos =
        graph.objects.where((SnapshotObject obj) => obj.klass.name == "Foo");
    expect(foos.length, equals(3));

    SnapshotObject bVertex = foos.singleWhere((SnapshotObject obj) {
      List<SnapshotObject> successors = obj.successors.toList();
      return successors[0].klass.name == "Null" &&
          successors[1].klass.name == "Null";
    });
    SnapshotObject aVertex = foos.singleWhere((SnapshotObject obj) {
      List<SnapshotObject> successors = obj.successors.toList();
      return successors[0].klass.name == "Foo" &&
          successors[1].klass.name == "Null";
    });
    SnapshotObject rVertex = foos.singleWhere((SnapshotObject obj) {
      List<SnapshotObject> successors = obj.successors.toList();
      return successors[0].klass.name == "Foo" &&
          successors[1].klass.name == "Foo";
    });

    // TODO(koda): Check actual byte sizes.

    expect(aVertex.retainedSize, equals(aVertex.shallowSize));
    expect(bVertex.retainedSize, equals(bVertex.shallowSize));
    expect(
        rVertex.retainedSize,
        equals(
            aVertex.shallowSize + bVertex.shallowSize + rVertex.shallowSize));

    List<SnapshotObject> lists = new List.from(
        graph.objects.where((SnapshotObject obj) => obj.klass.name == '_List'));
    expect(lists.length >= 2, isTrue);
    // Order by decreasing retained size.
    lists.sort((u, v) => v.retainedSize - u.retainedSize);
    SnapshotObject first = lists[0];
    expect(first.successors.length, greaterThanOrEqualTo(2));
    SnapshotObject second = lists[1];
    expect(second.successors.length, greaterThanOrEqualTo(1234569));
    // Check that the short list retains more than the long list inside.
    // and specifically, that it retains exactly itself + the long one.
    expect(first.retainedSize, equals(first.shallowSize + second.shallowSize));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
