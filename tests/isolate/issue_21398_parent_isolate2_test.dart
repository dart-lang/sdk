// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
// OtherScripts=deferred_loaded_lib.dart

import 'dart:isolate';
import 'dart:async';
import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';

import "deferred_loaded_lib.dart" deferred as lib;

// In this test case we send an object created from a deferred library
// that is loaded in the child isolate but not the parent isolate. The
// parent isolate does not know about the type of this object and throws
// an unhandled exception.
funcChild(args) {
  var replyPort = args[0];
  // Deferred load a library, create an object from that library and send
  // it over to the parent isolate which has not yet loaded that library.
  lib.loadLibrary().then((_) {
    replyPort.send(new lib.FromChildIsolate());
  });
}

void helperFunction() {
  var receivePort = new ReceivePort();
  asyncStart();

  // Spawn an isolate using spawnFunction.
  Isolate.spawn(funcChild, [receivePort.sendPort]).then((isolate) {
    receivePort.listen((msg) {
      // We don't expect to receive any valid messages.
      Expect.fail("We don't expect to receive any valid messages");
      receivePort.close();
      asyncEnd();
    }, onError: (e) {
      // We don't expect to receive any error messages, per spec listen
      // does not receive an error object.
      Expect.fail("We don't expect to receive any error messages");
      receivePort.close();
      asyncEnd();
    });
  });
}

main() {
  helperFunction(); //# 01: runtime error
}
