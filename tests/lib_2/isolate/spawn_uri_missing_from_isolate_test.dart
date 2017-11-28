// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that Isolate.spawnUri completes with an error when the given URI
/// doesn't resolve to an existing resource.
///
/// This test is similar to spawn_uri_missing_test.dart, but tests what happens
/// when Isolate.spawnUri is called from an a spawned isolate.  In dart2js,
/// these two situations are different.
library test.isolate.spawn_uri_missing_from_isolate_test;

import 'dart:isolate';

import 'dart:async';

import 'package:async_helper/async_helper.dart';

import 'spawn_uri_missing_test.dart';

const String SUCCESS = 'Test worked.';

void isolate(SendPort port) {
  doTest().then((_) => port.send(SUCCESS),
      onError: (error, stack) => port.send('Test failed: $error\n$stack'));
}

main() {
  ReceivePort port = new ReceivePort();
  Isolate.spawn(isolate, port.sendPort);
  Completer completer = new Completer();
  port.first.then((message) {
    if (message == SUCCESS) {
      completer.complete(null);
    } else {
      completer.completeError(message);
    }
  });

  asyncTest(() => completer.future);
}
