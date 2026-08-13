// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T> {}

mixin M<T> on C<T> {}

M<T> f<T>() {
  Expect.equals(T, int);
  // Don't have a value of M<T> to return, so throw and catch below.
  throw "no value";
}

main() {
  try {
    C<int> c = f();
  } catch (error) {
    Expect.equals("no value", error);
  }
}
