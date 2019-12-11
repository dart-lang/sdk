// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  foo(a
      : 1 // //# 01: syntax error
      = 1 // //# 02: syntax error
      ) {
    print(a);
  }

  static bar(a
      : 1 // //# 03: syntax error
      = 1 // //# 04: syntax error
      ) {
    print(a);
  }
}

baz(a
    : 1 // //# 05: syntax error
    = 1 // //# 06: syntax error
    ) {
  print(a);
}

main() {
  foo(a
      : 1 // //# 07: syntax error
      = 1 // //# 08: syntax error
      ) {
    print(a);
  }

  foo(1);

  new C().foo(2);

  C.bar(3);

  baz(4);
}
