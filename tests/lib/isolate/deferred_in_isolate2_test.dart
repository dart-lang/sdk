// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_in_isolate2_test;

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'deferred_in_isolate2_lib.dart' deferred as lib;

void loadDeferred(SendPort port) {
  lib.loadLibrary().then((_) {
    port.send(lib.f());
  });
}

void main() {
  asyncStart(2);
  var port = RawReceivePort();
  port.handler = (msg) {
    if (msg == null) {
      asyncEnd();
      port.close();
    } else if (msg case [String error, String stack]) {
      var remoteError = RemoteError("Error in isolate: $error", stack);
      Error.throwWithStackTrace(remoteError, remoteError.stackTrace);
    } else {
      Expect.equals("hi", msg);
      asyncEnd();
    }
  };
  Isolate.spawn(
    loadDeferred,
    port.sendPort,
    onError: port.sendPort,
    onExit: port.sendPort,
  );
}
