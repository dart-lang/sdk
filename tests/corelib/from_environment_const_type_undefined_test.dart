// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {}

const
    bool //  //# 01: ok
    int //   //# 02: compile-time error
    String //# 03: compile-time error
    Foo //   //# 04: compile-time error
    a = const bool.fromEnvironment('a');

const
    bool //  //# 05: ok
    int //   //# 06: compile-time error
    String //# 07: compile-time error
    Foo //   //# 08: compile-time error
    b = const bool.fromEnvironment('b');

const
    bool //  //# 09: compile-time error
    int //   //# 10: ok
    String //# 11: compile-time error
    Foo //   //# 12: compile-time error
    c = const int.fromEnvironment('c');

const
    bool //  //# 13: compile-time error
    int //   //# 14: compile-time error
    String //# 15: ok
    Foo //   //# 16: compile-time error
    d = const String.fromEnvironment('d');

main() {
  Expect.equals(a, false);
  Expect.equals(b, false);
  Expect.equals(c, null);
  Expect.equals(d, null);
}
