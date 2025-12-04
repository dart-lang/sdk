// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Environment=ASAN_OPTIONS=detect_stack_use_after_return=0

// ASAN's detect_stack_use_after_return (default on) has cost O(stack size) per
// longjmp/noreturn function.

main() {
  for (int i = 0; i < 1000000; ++i) {
    try {
      throw 'a';
    } catch (e) {}
  }
}
