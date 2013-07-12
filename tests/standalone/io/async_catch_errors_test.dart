// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';
import 'dart:io';

var events = [];

void testSocketException() {
  var completer = new Completer();
  runZonedExperimental(() {
    Socket.connect("4", 1).then((Socket s) {
      Expect.fail("Socket should not be able to connect");
    });
  }, onError: (err) {
    if (err is! SocketException) Expect.fail("Not expected error: $err");
    completer.complete("socket test, ok.");
    events.add("SocketException");
  });
  return completer.future;
}

void testFileException() {
  var completer = new Completer();
  runZonedExperimental(() {
    new File("lol it's not a file\n").openRead().listen(null);
  }, onError: (err) {
    if (err is! FileException) Expect.fail("Not expected error: $err");
    completer.complete("file test, ok.");
    events.add("FileException");
  });
  return completer.future;
}

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var timeOutPort = new ReceivePort();
  testSocketException()
    .then((_) => testFileException())
    .then((_) {
      timeOutPort.close();
      Expect.listEquals(["SocketException", "FileException"],
                        events);
    });
}
