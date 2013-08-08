// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multiple_isolate_list_script;

import 'dart:io';
import 'dart:isolate';

void isolateMain1() {
  // Spawn another isolate.
  spawnFunction(myIsolateName);
  // Kill this isolate.
  port.close();
}

void myIsolateName() {
  // Stay running.
  port.receive((a, b) {
    port.close();
  });
  print(''); // Print blank line to signal that we are ready.
}

main() {
  spawnFunction(isolateMain1);
  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
