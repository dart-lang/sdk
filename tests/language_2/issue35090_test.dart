// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int get g => 0;
}

class C implements A {
  noSuchMethod(Invocation i) {
    return 1;
  }
}

mixin M on A {
  int test() {
    return super.g;
  }

  noSuchMethod(Invocation i) {
    return 2;
  }
}

class MA extends C with M {}

main() {
  Expect.equals(new MA().g, 2);
  Expect.equals(new MA().test(), 2);
}
