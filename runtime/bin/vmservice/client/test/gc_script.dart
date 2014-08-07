// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gc_script;

import 'dart:async';
import 'dart:io';

List<int> data;

void grow(int iterations, int size, Duration duration) {
  if (iterations <= 0) {
    return;
  }
  data = new List<int>(size);
  new Timer(duration, () => grow(iterations - 1, size, duration));
}


main() {
  print(''); // Print blank line to signal that we are ready.
  
  grow(100, 1 << 24, new Duration(seconds: 1));  
  
  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
