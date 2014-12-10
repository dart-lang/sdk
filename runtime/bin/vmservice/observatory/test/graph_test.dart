// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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
  lst[0] = lst;  // Self-loop.
  // Larger than any other fixed-size list in a fresh heap.
  lst[1] = new List(123456);
}

int fooId;

var tests = [

(Isolate isolate) {
  Completer completer = new Completer();
  isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == '_Graph') {
      ReadStream reader = new ReadStream(event.data);
      ObjectGraph graph = new ObjectGraph(reader);
      expect(fooId, isNotNull);
      Iterable<ObjectVertex> foos = graph.vertices.where(
          (ObjectVertex obj) => obj.classId == fooId);
      expect(foos.length, equals(3));
      expect(foos.where(
          (ObjectVertex obj) => obj.succ.length == 0).length, equals(1));
      expect(foos.where(
          (ObjectVertex obj) => obj.succ.length == 1).length, equals(1));
      expect(foos.where(
          (ObjectVertex obj) => obj.succ.length == 2).length, equals(1));
      
      ObjectVertex bVertex = foos.where(
          (ObjectVertex obj) => obj.succ.length == 0).first;
      ObjectVertex aVertex = foos.where(
          (ObjectVertex obj) => obj.succ.length == 1).first;
      ObjectVertex rVertex = foos.where(
          (ObjectVertex obj) => obj.succ.length == 2).first;
      
      // TODO(koda): Check actual byte sizes.

      expect(aVertex.retainedSize, equals(aVertex.shallowSize));
      expect(bVertex.retainedSize, equals(bVertex.shallowSize));
      expect(rVertex.retainedSize, equals(aVertex.shallowSize +
                                          bVertex.shallowSize +
                                          rVertex.shallowSize));
      
      const int fixedSizeListCid = 62;
      List<ObjectVertex> lists = new List.from(graph.vertices.where(
          (ObjectVertex obj) => obj.classId == fixedSizeListCid));
      expect(lists.length >= 2, isTrue);
      // Order by decreasing retained size.
      lists.sort((u, v) => v.retainedSize - u.retainedSize);
      ObjectVertex first = lists[0];
      ObjectVertex second = lists[1];
      // Check that the short list retains more than the long list inside.
      expect(first.succ.length, equals(2 + second.succ.length));
      // ... and specifically, that it retains exactly itself + the long one.
      expect(first.retainedSize,
          equals(first.shallowSize + second.shallowSize));
      completer.complete();
    }
  });
  return isolate.rootLib.load().then((Library lib) {
    expect(lib.classes.length, equals(1));
    Class fooClass = lib.classes.first;
    fooId = fooClass.vmCid;
    isolate.get('graph');
    return completer.future;
  });
},

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);