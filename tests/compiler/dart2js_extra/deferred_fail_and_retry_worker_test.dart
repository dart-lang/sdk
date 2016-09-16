// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that when a deferred import from a worker fails to load, it is possible
// to retry.

import "deferred_fail_and_retry_lib.dart" deferred as lib;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:isolate";
import "dart:js" as js;

void test(SendPort sendPort) {
  // Patch XMLHttpRequest to fail on first load.
  js.context.callMethod("eval", [
    """
    oldXMLHttpRequest = XMLHttpRequest;
    XMLHttpRequest = function() {
      XMLHttpRequest = oldXMLHttpRequest;
      var instance = new XMLHttpRequest();
      this.addEventListener = function(x, y, z) {
        instance.addEventListener(x, y, z);
      }
      this.send = function() {
        instance.send();
      }
      this.open = function(x, uri) {
        instance.open(x, "non_existing.js");
      }
    }
  """
  ]);
  lib.loadLibrary().then((_) {
    sendPort.send("Library should not have loaded");
  }, onError: (error) {
    sendPort.send("failed");
    lib.loadLibrary().then((_) {
      sendPort.send(lib.foo());
    }, onError: (error) {
      sendPort.send("Library should have loaded this time $error");
    });
  });
}

main() {
  ReceivePort receivePort = new ReceivePort();
  asyncStart();
  bool receivedFailed = false;
  receivePort.listen((message) {
    if (!receivedFailed) {
      Expect.equals("failed", message);
      receivedFailed = true;
    } else {
      Expect.equals("loaded", message);
      asyncEnd();
    }
  });
  Isolate.spawn(test, receivePort.sendPort);
}
