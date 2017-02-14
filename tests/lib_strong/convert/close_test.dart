// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:convert";

class MySink implements Sink<List<int>> {
  List<int> accumulated = <int>[];
  bool isClosed = false;

  add(List<int> list) {
    accumulated.addAll(list);
    list.length;
  }

  close() {
    isClosed = true;
  }
}

main() {
  var mySink = new MySink();
  var byteSink = new ByteConversionSink.from(mySink);
  byteSink.add([1, 2, 3]);
  byteSink.close();
  Expect.listEquals([1, 2, 3], mySink.accumulated);
  Expect.isTrue(mySink.isClosed);
}
