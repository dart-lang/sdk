// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

// VM processes collected samples using two different mechanisms: by
// scheduling VM interrupts and via `SampleBlockProcessor` which periodically
// wakes up and checks if any thread has unprocessed blocks. To test both
// mechanisms we introduce a way to run this script and suppress interrupts
// within `fib` function - this way completed blocks will be processed by
// `SampleBlockProcessor`.
const noInterrupts =
    bool.fromEnvironment('disable.interrupts.to.test.sample.block.processor')
        ? pragma('vm:unsafe:no-interrupts')
        : Object();

@noInterrupts
fib(int n) {
  if (n <= 1) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

void main() {
  final tag = UserTag('Testing')..makeCurrent();
  final tag2 = UserTag('Baz');
  int i = 35;
  while (true) {
    tag.makeCurrent();
    fib(i);
    tag2.makeCurrent();
    fib(i);
  }
}
