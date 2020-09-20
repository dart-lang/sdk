// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests identifier usage of keywords `out` and `inout`, correct usage of `in`.

import "package:expect/expect.dart";

class A<out> {}

class B<inout> {}

class C<out, inout> {}

F<inout, out>() {}

mixin G<out, inout> {}

typedef H<inout, out> = out Function(inout);

class OutParameter {
  var out = 3;
  int func(int out) {
    return out;
  }
}

class inout {
  void out(int x) {}
}

var out = 5;

main() {
  OutParameter x = new OutParameter();
  Expect.equals(2, x.func(2));
  Expect.equals(3, x.out);

  inout foo = inout();
  foo.out(4);

  Expect.equals(5, out);

  var collection = [0, 1, 2];
  for (var x in collection) {
    Expect.isTrue(x is int);
  }
}
