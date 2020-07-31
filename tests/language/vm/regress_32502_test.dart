// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that VM does not omit type checks from closure prologues.

import "package:expect/expect.dart";

void invoke(dynamic f, dynamic arg) {
  f(arg);
}

void main() {
  dynamic x = 42;

  foo(int v) {
    x = v;
  }

  bar<T>() {
    return (T v) {
      x = v;
    };
  }

  Expect.throwsTypeError(() => invoke(foo, "hello"));
  Expect.throwsTypeError(() => invoke(bar<int>(), "hello"));
  Expect.equals(42, x);
}
