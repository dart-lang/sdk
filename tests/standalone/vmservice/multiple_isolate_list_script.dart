// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multiple_isolate_list_script;

import 'dart:io';
import 'dart:isolate';

void isolateMain1(_) {
  // Spawn another isolate.
  Isolate.spawn(myIsolateName, null);
}

void myIsolateName(_) {
  // Stay running.
  new ReceivePort().first.then((a) { });
  print(''); // Print blank line to signal that we are ready.
}

main() {
  Isolate.spawn(isolateMain1, null);
  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
