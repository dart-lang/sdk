// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--stacktrace_every=1 --deterministic

void foo1(par) {
  try {
    () {
      // The parameter `par` has to be captured within a closure, but it doesn't
      // matter whether or not it's actually used.
      print(par.runtimeType);
    };
    // We need to throw, otherwise the crash doesn't happen. We don't need to
    // catch it explicitly, however.
    throw '';
  } finally {
    // We need to trigger a lot of stack overflow checks. Somewhere around
    // 20000 seems to work.
    int x = 0;
    for (int loc1 = 0; loc1 < 20000; loc1++) {
      x += loc1;
    }
    print(x);
  }
}

main() {
  try {
    // Parameter isn't important.
    foo1(null);
  } catch (e) {
    print('foo1 threw');
  }
}
