// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import "package:expect/expect.dart";
import "package:expect/async_helper.dart";

void entry(SendPort replyTo) {
  replyTo.send("foo");
}

main() {
  asyncStart();
  ReceivePort response = new ReceivePort();
  Isolate.spawn(entry, response.sendPort);
  response.first.then((message) {
    Expect.equals("foo", message);
    asyncEnd();
  });
}
