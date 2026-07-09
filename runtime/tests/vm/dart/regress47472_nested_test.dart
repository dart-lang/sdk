// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Environment=ASAN_OPTIONS=detect_stack_use_after_return=0

// ASAN's detect_stack_use_after_return (default on) has cost O(stack size) per
// longjmp/noreturn function.

@pragma("vm:never-inline")
foo(n) {
  try {
    throw 'a';
  } catch (e) {}
  if (n > 0) {
    // Function.apply is implemented as a native, so this introduces new entry
    // frames, checking that DartEntryScope saves things as needed.
    Function.apply(() => foo(n - 1), []);
    Function.apply(() => bar(n - 1), []);
  }
  try {
    throw 'a';
  } catch (e) {}
}

// Stagger stack depth.
@pragma("vm:never-inline")
bar(n) {
  foo(0);
  foo(n);
  foo(0);
}

main() {
  foo(10);
}
