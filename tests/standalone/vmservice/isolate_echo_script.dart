// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_echo_script;

import 'dart:io';

main() {
  print(''); // Print blank line to signal that we are ready.

  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
