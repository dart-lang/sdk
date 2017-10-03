// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  foo(a
      : 1 // //# 01: compile-time error
      = 1 // //# 02: compile-time error
      ) {
    print(a);
  }

  static bar(a
      : 1 // //# 03: compile-time error
      = 1 // //# 04: compile-time error
      ) {
    print(a);
  }
}

baz(a
    : 1 // //# 05: compile-time error
    = 1 // //# 06: compile-time error
    ) {
  print(a);
}

main() {
  foo(a
      : 1 // //# 07: compile-time error
      = 1 // //# 08: compile-time error
      ) {
    print(a);
  }

  foo(1);

  new C().foo(2);

  C.bar(3);

  baz(4);
}
