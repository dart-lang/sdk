// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=null-aware-elements

import 'package:expect/expect.dart';

String log = "";

T sideEffect<T>(T t) {
  log = "${log}:${t}";
  return t;
}

main() {
  log = "";
  var map1 = {sideEffect<String>("one"): ?sideEffect<String?>("two")};
  Expect.equals(log, ":one:two");
  log = "";
  var map2 = {
    sideEffect<int>(0): sideEffect<int>(1),
    sideEffect<int>(2): ?sideEffect<int?>(3),
    ?sideEffect<int?>(4): sideEffect<int>(5),
    ?sideEffect<int?>(6): ?sideEffect<int?>(7),
  };
  Expect.equals(log, ":0:1:2:3:4:5:6:7");
  log = "";
  var map3 = {
    sideEffect<int>(0): sideEffect<int>(1),
    sideEffect<int>(2): ?sideEffect<int?>(3),
    ?sideEffect<int?>(null): sideEffect<int>(5),
    ?sideEffect<int?>(null): ?sideEffect<int?>(7),
  };
  Expect.equals(log, ":0:1:2:3:null:null");

  log = "";
  var list1 = [sideEffect<String>("one"), ?sideEffect<String?>("two")];
  Expect.equals(log, ":one:two");
  log = "";
  var list2 = [
    sideEffect<int>(0), sideEffect<int>(1),
    sideEffect<int>(2), ?sideEffect<int?>(3),
    ?sideEffect<int?>(4), sideEffect<int>(5),
    ?sideEffect<int?>(6), ?sideEffect<int?>(7),
  ];
  Expect.equals(log, ":0:1:2:3:4:5:6:7");
  log = "";
  var list3 = [
    sideEffect<int>(0), sideEffect<int>(1),
    sideEffect<int>(2), ?sideEffect<int?>(3),
    ?sideEffect<int?>(null), sideEffect<int>(5),
    ?sideEffect<int?>(null), ?sideEffect<int?>(7),
  ];
  Expect.equals(log, ":0:1:2:3:null:5:null:7");

  log = "";
  var set1 = {sideEffect<String>("one"), ?sideEffect<String?>("two")};
  Expect.equals(log, ":one:two");
  log = "";
  var set2 = {
    sideEffect<int>(0), sideEffect<int>(1),
    sideEffect<int>(2), ?sideEffect<int?>(3),
    ?sideEffect<int?>(4), sideEffect<int>(5),
    ?sideEffect<int?>(6), ?sideEffect<int?>(7),
  };
  Expect.equals(log, ":0:1:2:3:4:5:6:7");
  log = "";
  var set3 = {
    sideEffect<int>(0), sideEffect<int>(1),
    sideEffect<int>(2), ?sideEffect<int?>(3),
    ?sideEffect<int?>(null), sideEffect<int>(5),
    ?sideEffect<int?>(null), ?sideEffect<int?>(7),
  };
  Expect.equals(log, ":0:1:2:3:null:5:null:7");
}
