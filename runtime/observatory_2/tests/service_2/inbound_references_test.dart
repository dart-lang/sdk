// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library inbound_references_test;

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

class Node {
  // Make sure this field is not removed by the tree shaker.
  @pragma("vm:entry-point")
  var edge;
}

class Edge {}

var n, e, array;

void script() {
  n = new Node();
  e = new Edge();
  n.edge = e;
  array = new List(2);
  array[0] = n;
  array[1] = e;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load();
    Field field = lib.variables.where((v) => v.name == 'e').single;
    await field.load();
    Instance e = field.staticValue;
    ServiceMap response = await isolate.getInboundReferences(e, 100);
    List references = response['references'];
    hasReferenceSuchThat(predicate) {
      expect(references.any(predicate), isTrue);
    }

    // Assert e is referenced by at least n, array, and the top-level
    // field e.
    hasReferenceSuchThat((r) =>
        r['parentField'] != null &&
        r['parentField'].name == 'edge' &&
        r['source'].isInstance &&
        r['source'].clazz.name == 'Node');
    hasReferenceSuchThat(
        (r) => r['parentListIndex'] == 1 && r['source'].isList);
    hasReferenceSuchThat(
        (r) => r['source'] is Field && r['source'].name == 'e');
  }
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
