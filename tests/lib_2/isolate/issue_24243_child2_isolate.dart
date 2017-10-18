// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

main(List<String> args, message) {
  var sendPort = message;
  try {
    var map0 = <int, String>{1: 'one', 2: 'two', 3: 'three'};
    var map1 = <int, String>{4: 'four', 5: 'five', 6: 'six'};
    var map2 = <int, String>{7: 'seven', 8: 'eight', 9: 'nine'};
    var map = new Map<int, Map<int, String>>.from({0: map0, 1: map1, 2: map2});
    sendPort.send(map);
  } catch (error) {
    sendPort.send("Invalid Argument(s).");
  }
}
