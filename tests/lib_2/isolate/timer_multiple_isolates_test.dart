// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_multiple_isolates_test;

import 'dart:isolate';
import 'dart:async';

child(msg) {
  var i = msg[0];
  var reponsePort = msg[1];
  print("Starting child $i");

  // Keep this isolate running to prevent its shutdown from touching the event
  // handler.
  new RawReceivePort();

  // Try to get separate wakeups for each isolate.
  new Timer(new Duration(milliseconds: 100 * (i + 1)), () {
    print("Timer fired $i");
    reponsePort.send(null);
  });
}

main() {
  var port;
  var replies = 0;
  var n = 3;
  port = new RawReceivePort((reply) {
    replies++;
    print("Got reply $replies");
    if (replies == n) {
      print("Done");
      port.close();
    }
  });

  for (var i = 0; i < n; i++) {
    Isolate.spawn(child, [i, port.sendPort]);
  }
}
