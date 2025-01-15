// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of nested spawning of isolates from a URI

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncTest(() async {
    final port = ReceivePort();
    final exitPort = ReceivePort();
    Isolate.spawnUri(
      Uri.parse('spawn_uri_nested_child1_vm_isolate.dart'),
      [],
      [
        [1, 2],
        port.sendPort,
      ],
      onExit: exitPort.sendPort,
    );
    asyncStart();
    port.first.then(asyncSuccess);
    // ensure main isolate doesn't exit before child isolate exits
    await exitPort.first;
  });
}
