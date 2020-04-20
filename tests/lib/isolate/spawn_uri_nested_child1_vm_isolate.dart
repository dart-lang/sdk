// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of nested spawning of isolates from a URI
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
library NestedSpawnUriChild1Library;

import 'dart:isolate';

main(List<String> args, message) {
  ReceivePort port2 = new ReceivePort();
  port2.listen((msg) {
    if (msg != "re: hi") throw "Bad response: $msg";
    port2.close();
  });

  Isolate.spawnUri(Uri.parse('spawn_uri_nested_child2_vm_isolate.dart'), ['hi'],
      port2.sendPort);

  var data = message[0];
  var replyTo = message[1];
  replyTo.send(data);
}
