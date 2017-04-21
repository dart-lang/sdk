// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deferred libraries are supported from isolates other than the root
// isolate.

import 'dart:isolate';

main() {
  try {
    var receivePort = new RawReceivePort();
    var expectedMsg = "Deferred Loaded.";

    receivePort.handler = (msg) {
      if (msg != expectedMsg) {
        print("Test failed.");
        throw msg; // Fail the test if the message is not expected.
      }
      print('Test done.');
      receivePort.close();
    };

    var stopwatch = new Stopwatch()..start();
    Isolate.spawnUri(new Uri(path: 'deferred_in_isolate_app.dart'),
        [expectedMsg], [receivePort.sendPort]).then((isolate) {
      print('Isolate spawn: ${stopwatch.elapsedMilliseconds}ms');
    }).catchError((error) {
      print(error);
    });
  } catch (exception, stackTrace) {
    print('Test failed.');
    print(exception);
    print(stackTrace);
    rethrow;
  }
}
