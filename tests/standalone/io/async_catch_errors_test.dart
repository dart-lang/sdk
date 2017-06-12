// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

var events = [];

Future testSocketException() {
  var completer = new Completer();
  runZoned(() {
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

Future testFileSystemException() {
  var completer = new Completer();
  runZoned(() {
    new File("lol it's not a file\n").openRead().listen(null);
  }, onError: (err) {
    if (err is! FileSystemException) Expect.fail("Not expected error: $err");
    completer.complete("file test, ok.");
    events.add("FileSystemException");
  });
  return completer.future;
}

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  asyncStart();
  testSocketException().then((_) => testFileSystemException()).then((_) {
    asyncEnd();
    Expect.listEquals(["SocketException", "FileSystemException"], events);
  });
}
