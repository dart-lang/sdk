// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library allocations_script;

import 'dart:io';
import 'dart:profiler';

main() {
  var counter = new Counter('a.b.c', 'description');
  Metrics.register(counter);
  counter.value = 1234.5;

  print(''); // Print blank line to signal that we are ready.
  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
