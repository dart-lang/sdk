// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:isolate';

main(List<String> args, message) {
  var sendPort = message;
  try {
    var map0 = new LinkedHashMap<int, String>();
    map0[1] = 'one';
    map0[2] = 'two';
    map0[3] = 'three';
    var map1 = new LinkedHashMap<int, String>();
    map1[4] = 'four';
    map1[5] = 'five';
    map1[6] = 'size';
    var map2 = new LinkedHashMap<int, String>();
    map2[7] = 'seven';
    map2[8] = 'eight';
    map2[9] = 'nine';

    var map = new Map<int, LinkedHashMap<int, String>>.from(
        {0: map0, 1: map1, 2: map2});
    sendPort.send(map);
  } catch (error) {
    sendPort.send("Invalid Argument(s).");
  }
}
