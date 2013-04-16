// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of nested spawning of isolates from a URI
// Note: the following comment is used by test.dart to additionally compile the
// other isolate's code.
library NestedSpawnUriChild1Library;
import 'dart:isolate';

main() {
  ReceivePort port2 = new ReceivePort();
  port2.receive((msg, SendPort replyTo) {
    port2.close();
  });

  SendPort s = spawnUri('spawn_uri_nested_child2_vm_isolate.dart');
  s.send('hi', port2.toSendPort());

  port.receive((message, SendPort replyTo) {
    var result = message;
    replyTo.send(result);
  });
}
