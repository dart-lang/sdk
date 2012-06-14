// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  int takesAnInt(int val) {
    return val + 1;
  }
}

takesAnInt(int val) {
  return val + 1;
}

main() {
  Expect.equals("foo1", new Foo().takesAnInt("foo"));
  Expect.equals("foo1", takesAnInt("foo"));
}
