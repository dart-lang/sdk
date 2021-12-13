// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Example of nested spawning of isolates from a URI
library NestedSpawnUriLibrary;

import 'dart:isolate';
import 'package:async_helper/async_minitest.dart';

main() {
  test('isolate fromUri - nested send and reply', () async {
    final port = ReceivePort();
    final exitPort = ReceivePort();
    Isolate.spawnUri(
        Uri.parse('spawn_uri_nested_child1_vm_isolate.dart'),
        [],
        [
          [1, 2],
          port.sendPort
        ],
        onExit: exitPort.sendPort);
    port.first.then(expectAsync((result) => print(result)));
    // ensure main isolate doesn't exit before child isolate exits
    await exitPort.first;
  });
}
