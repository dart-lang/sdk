// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' as isolate;
import 'package:observatory/object_graph.dart';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

// Make sure these fields are not removed by the tree shaker.
@pragma("vm:entry-point")
dynamic bigGlobal;

child(message) {
  var bigString = message[0] as String;
  var replyPort = message[1] as isolate.SendPort;
  bigGlobal = bigString;
  replyPort.send(null);
  new isolate.RawReceivePort(); // Keep child alive.
}

void script() {
  var bigString = "x" * (1 << 20);
  var port;
  for (var i = 0; i < 2; i++) {
    port = new isolate.RawReceivePort((_) => port.close());
    isolate.Isolate.spawn(child, [bigString, port.sendPort]);
  }
  bigGlobal = bigString;
  print("Ready");
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var graph = await isolate.fetchHeapSnapshot().done;

    // We are assuming the big string is the largest in the heap, and that it
    // was shared/pass-by-pointer.
    List<SnapshotObject> strings = graph.objects
        .where((SnapshotObject obj) => obj.klass.name == "_OneByteString")
        .toList();
    strings.sort((u, v) => v.shallowSize - u.shallowSize);
    SnapshotObject bigString = strings[0];
    print("bigString: $bigString");
    expect(bigString.shallowSize, greaterThanOrEqualTo(1 << 20));

    int matchingPredecessors = 0;
    for (SnapshotObject predecessor in bigString.predecessors) {
      print("predecessor $predecessor ${predecessor.label}");
      if (predecessor.label.contains("bigGlobal") &&
          predecessor.klass.name.contains("Isolate")) {
        matchingPredecessors++;
      }
    }

    for (SnapshotObject object in graph.objects) {
      if (object.klass.name.contains("Isolate")) {
        print("$object / ${object.description}");
      }
    }

    // Parent and two children. Seeing all 3 means we visited all the field tables.
    expect(matchingPredecessors, equals(3));
  }
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
