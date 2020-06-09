// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Regression test for Issue 12320, Issue 12363.

String log = '';
int x;

void main() {
  (run)(run);
  // The little dance with passing [run] as an argument to confuse the optimizer
  // so that [run] is not inlined.  If [run] is inlined, the bug (Issue 12320)
  // eliminates the following 'Expect', making the test appear to pass!
  Expect.equals('[Foo][Foo 1][Bar][Foo][Foo 0]', log);
}

void run(f) {
  if (f is! int) {
    f(1);
  } else {
    x = f;
    callFoo();
    x = 2;
    callBar();
    callFoo();
  }
}

void callFoo() {
  log += '[Foo]';
  switch (x) {
    case 0:
      log += '[Foo 0]';
      break;
    case 1:
      log += '[Foo 1]';
      break;
    default:
      throw 'invalid x';
  }
}

void callBar() {
  log += '[Bar]';
  x = 0;
}
