// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/heap_snapshot.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/object_graph.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo {
  Object left;
  Object right;
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

int fooId;

var tests = [
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load();
    expect(lib.classes.length, equals(1));
    Class fooClass = lib.classes.first;
    fooId = fooClass.vmCid;

    RawHeapSnapshot raw =
        await isolate.fetchHeapSnapshot(M.HeapSnapshotRoots.vm, false).last;
    HeapSnapshot snapshot = new HeapSnapshot();
    await snapshot.loadProgress(isolate, raw).last;
    ObjectGraph graph = snapshot.graph;

    expect(fooId, isNotNull);
    Iterable<ObjectVertex> foos =
        graph.vertices.where((ObjectVertex obj) => obj.vmCid == fooId);
    expect(foos.length, equals(3));
    expect(foos.where((obj) => obj.successors.length == 0).length, equals(1));
    expect(foos.where((obj) => obj.successors.length == 1).length, equals(1));
    expect(foos.where((obj) => obj.successors.length == 2).length, equals(1));

    ObjectVertex bVertex =
        foos.where((ObjectVertex obj) => obj.successors.length == 0).first;
    ObjectVertex aVertex =
        foos.where((ObjectVertex obj) => obj.successors.length == 1).first;
    ObjectVertex rVertex =
        foos.where((ObjectVertex obj) => obj.successors.length == 2).first;

    // TODO(koda): Check actual byte sizes.

    expect(aVertex.retainedSize, equals(aVertex.shallowSize));
    expect(bVertex.retainedSize, equals(bVertex.shallowSize));
    expect(
        rVertex.retainedSize,
        equals(
            aVertex.shallowSize + bVertex.shallowSize + rVertex.shallowSize));

    Library corelib =
        isolate.libraries.singleWhere((lib) => lib.uri == 'dart:core');
    await corelib.load();
    Class _List =
        corelib.classes.singleWhere((cls) => cls.vmName.startsWith('_List'));
    int kArrayCid = _List.vmCid;
    // startsWith to ignore the private mangling
    List<ObjectVertex> lists = new List.from(
        graph.vertices.where((ObjectVertex obj) => obj.vmCid == kArrayCid));
    expect(lists.length >= 2, isTrue);
    // Order by decreasing retained size.
    lists.sort((u, v) => v.retainedSize - u.retainedSize);
    ObjectVertex first = lists[0];
    ObjectVertex second = lists[1];
    // Check that the short list retains more than the long list inside.
    expect(first.successors.length, equals(2 + second.successors.length));
    // ... and specifically, that it retains exactly itself + the long one.
    expect(first.retainedSize, equals(first.shallowSize + second.shallowSize));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
