// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/object_graph.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

class Foo {
  // Make sure these fields are not removed by the tree shaker.
  @pragma("vm:entry-point")
  dynamic left;
  @pragma("vm:entry-point")
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
    var graph = await isolate.fetchHeapSnapshot().done;

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

    // Verify sizes of classes are the appropriates sums of their instances.
    // This also verifies that the class instance iterators are visiting the
    // correct set of objects (e.g., not including dead objects).
    for (SnapshotClass klass in graph.classes) {
      int shallowSum = 0;
      int internalSum = 0;
      int externalSum = 0;
      for (SnapshotObject instance in klass.instances) {
        if (instance == graph.root) {
          // The root may have 0 self size.
          expect(instance.internalSize, greaterThanOrEqualTo(0));
          expect(instance.externalSize, greaterThanOrEqualTo(0));
          expect(instance.shallowSize, greaterThanOrEqualTo(0));
        } else {
          // All other objects are heap objects with positive size.
          expect(instance.internalSize, greaterThan(0));
          expect(instance.externalSize, greaterThanOrEqualTo(0));
          expect(instance.shallowSize, greaterThan(0));
        }
        expect(instance.retainedSize, greaterThan(0));
        expect(instance.shallowSize,
            equals(instance.internalSize + instance.externalSize));
        shallowSum += instance.shallowSize;
        internalSum += instance.internalSize;
        externalSum += instance.externalSize;
      }
      expect(shallowSum, equals(klass.shallowSize));
      expect(internalSum, equals(klass.internalSize));
      expect(externalSum, equals(klass.externalSize));
      expect(
          klass.shallowSize, equals(klass.internalSize + klass.externalSize));
    }

    // Verify sizes of the overall graph are the appropriates sums of all
    // instances. This also verifies that the all instances iterator is visiting
    // the correct set of objects (e.g., not including dead objects).
    int shallowSum = 0;
    int internalSum = 0;
    int externalSum = 0;
    for (SnapshotObject instance in graph.objects) {
      if (instance == graph.root) {
        // The root may have 0 self size.
        expect(instance.internalSize, greaterThanOrEqualTo(0));
        expect(instance.externalSize, greaterThanOrEqualTo(0));
        expect(instance.shallowSize, greaterThanOrEqualTo(0));
      } else {
        // All other objects are heap objects with positive size.
        expect(instance.internalSize, greaterThan(0));
        expect(instance.externalSize, greaterThanOrEqualTo(0));
        expect(instance.shallowSize, greaterThan(0));
      }
      expect(instance.retainedSize, greaterThan(0));
      expect(instance.shallowSize,
          equals(instance.internalSize + instance.externalSize));
      shallowSum += instance.shallowSize;
      internalSum += instance.internalSize;
      externalSum += instance.externalSize;
    }
    expect(shallowSum, equals(graph.size));
    expect(internalSum, equals(graph.internalSize));
    expect(externalSum, equals(graph.externalSize));
    expect(graph.size, equals(graph.internalSize + graph.externalSize));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
