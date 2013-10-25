// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_stacktrace_command_script;

import 'dart:io';
import 'dart:isolate';

void a() {
  int x = 0;
  print(''); // Print blank line to signal that we are ready.
  while (true) {
    x &= x;
  }
}

void b() {
  a();
}

class C {
  c() {
    b();
  }
}

void myIsolateName(_) {
  new C().c();
}

main() {
  Isolate.spawn(myIsolateName, null);
  // Wait until signaled from spawning test.
  stdin.first.then((_) => exit(0));
}
