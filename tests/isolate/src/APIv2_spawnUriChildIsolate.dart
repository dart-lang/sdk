// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Child isolate code to be spawned from a URI to this file.
#library('SpawnUriChildIsolate');
#import('dart:isolate');

void isolateMain(ReceivePort port) {
  port.receive((msg, reply) => reply.send("re: $msg"));
}

// Just for frog's sake.  TODO(eub): clean this up when we're able to.
main() {
  if (false) {
    isolateMain(null);
    new ReceivePort();
  }
}
