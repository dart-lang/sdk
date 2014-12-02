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
Foo root;

void script() {
  // Create 3 instances of Foo, with out-degrees 0 (for b), 1 (for a), and 2 (for root).
  root = new Foo();
  var a = new Foo();
  var b = new Foo();
  root.left = a;
  root.right = b;
  a.left = b;
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
      List<ObjectVertex> foos = graph.vertices.where((ObjectVertex obj) => obj.classId == fooId);
      expect(foos.length, equals(3));
      expect(foos.where((ObjectVertex obj) => obj.succ.length == 0).length, equals(1));
      expect(foos.where((ObjectVertex obj) => obj.succ.length == 1).length, equals(1));
      expect(foos.where((ObjectVertex obj) => obj.succ.length == 2).length, equals(1));
      completer.complete();
    }
  });
  return isolate.rootLib.load().then((Library lib) {
    expect(lib.classes.length, equals(1));
    // Extract the numerical class id of 'Foo', used in the event listener above.
    Class fooClass = lib.classes.first;
    String prefix = "classes/";
    // TODO(koda): Add method on Class to get numerical id.
    fooId = int.parse(fooClass.id.substring(prefix.length));
    isolate.get('graph');
    return completer.future;
  });
},

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);