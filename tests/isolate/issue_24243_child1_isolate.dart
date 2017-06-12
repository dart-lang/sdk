// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

main(List<String> args, message) {
  var sendPort = message;
  try {
    var list0 = <int>[1, 2, 3];
    var list1 = <int>[4, 5, 6];
    var list2 = <int>[7, 8, 9];
    var list = new List<List<int>>.from([list0, list1, list2]);
    sendPort.send(list);
  } catch (error) {
    sendPort.send("Invalid Argument(s).");
  }
}
