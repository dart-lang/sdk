// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:isolate';

import "package:expect/expect.dart";

main() {
  // First spawn an isolate using spawnURI and have it
  // send back a "literal" like list object.
  var receive1 = new ReceivePort();
  Isolate.spawnUri(
          Uri.parse('issue_24243_child1_isolate.dart'), [], receive1.sendPort)
      .then((isolate) {
    receive1.listen((msg) {
      var list0 = <int>[1, 2, 3];
      var list1 = <int>[4, 5, 6];
      var list2 = <int>[7, 8, 9];
      Expect.isTrue(msg is List<List<int>>);
      Expect.listEquals(msg[0], list0);
      Expect.listEquals(msg[1], list1);
      Expect.listEquals(msg[2], list2);
      Expect.throws(() => msg[0] = "throw an exception");
      receive1.close();
    }, onError: (e) => print('$e'));
  });

  // Now spawn an isolate using spawnURI and have it
  // send back a "literal" like map object.
  var receive2 = new ReceivePort();
  Isolate.spawnUri(
          Uri.parse('issue_24243_child2_isolate.dart'), [], receive2.sendPort)
      .then((isolate) {
    receive2.listen((msg) {
      var map0 = <int, String>{1: 'one', 2: 'two', 3: 'three'};
      var map1 = <int, String>{4: 'four', 5: 'five', 6: 'six'};
      var map2 = <int, String>{7: 'seven', 8: 'eight', 9: 'nine'};
      Expect.isTrue(msg is Map<int, Map<int, String>>);
      Expect.mapEquals(msg[0], map0);
      Expect.mapEquals(msg[1], map1);
      Expect.mapEquals(msg[2], map2);
      Expect.throws(() => msg[0] = "throw an exception");
      receive2.close();
    }, onError: (e) => print('$e'));
  });
}
