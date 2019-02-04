// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

class Pair {
  var x, y;
}

var p1;
var p2;

buildGraph() {
  p1 = new Pair();
  p2 = new Pair();

  // Adds to both reachable and retained size.
  p1.x = new List();
  p2.x = new List();

  // Adds to reachable size only.
  p1.y = p2.y = new List();
}

Future<int> getReachableSize(ServiceObject obj) async {
  Instance size = await obj.isolate.getReachableSize(obj);
  return int.parse(size.valueAsString);
}

Future<int> getRetainedSize(ServiceObject obj) async {
  Instance size = await obj.isolate.getRetainedSize(obj);
  return int.parse(size.valueAsString);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Instance p1 = await rootLibraryFieldValue(isolate, "p1");
    Instance p2 = await rootLibraryFieldValue(isolate, "p2");

    // In general, shallow <= retained <= reachable. In this program,
    // 0 < shallow < retained < reachable.

    int p1_shallow = p1.size;
    int p1_retained = await getRetainedSize(p1);
    int p1_reachable = await getReachableSize(p1);

    expect(0, lessThan(p1_shallow));
    expect(p1_shallow, lessThan(p1_retained));
    expect(p1_retained, lessThan(p1_reachable));

    int p2_shallow = p2.size;
    int p2_retained = await getRetainedSize(p2);
    int p2_reachable = await getReachableSize(p2);

    expect(0, lessThan(p2_shallow));
    expect(p2_shallow, lessThan(p2_retained));
    expect(p2_retained, lessThan(p2_reachable));

    expect(p1_shallow, equals(p2_shallow));
    expect(p1_retained, equals(p2_retained));
    expect(p1_reachable, equals(p2_reachable));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: buildGraph);
