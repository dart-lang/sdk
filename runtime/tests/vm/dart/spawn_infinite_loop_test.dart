// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import 'dart:isolate';

// This test ensures that the VM can kill the spawned isolate during VM
// shutdown even when the isolate is in an infinite loop and will not finish
// on its own.

void loop(msg) {
  while (true) {}
  throw "Unreachable";
}

void main() {
  Isolate.spawn(loop, []);
}
