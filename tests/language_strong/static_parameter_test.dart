// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(x
    , static int y // //# 01: compile-time error
    , final static y // //# 02: compile-time error
    , {static y} // //# 03: compile-time error
    , [static y] // //# 04: compile-time error
    ) {}

class C {
  bar(x
      , static int y // //# 05: compile-time error
      , final static y // //# 06: compile-time error
      , {static y} // //# 07: compile-time error
      , [static y] // //# 08: compile-time error
      ) {}

  static baz(x
      , static int y // //# 09: compile-time error
      , final static y // //# 10: compile-time error
      , {static y} // //# 11: compile-time error
      , [static y] // //# 12: compile-time error
      ) {}
}

main() {
  foo(1
      , 1 // //# 01: continued
      , 1 // //# 02: continued
      , y: 1 // //# 03: continued
      , 1 // //# 04: continued
      );
  new C().bar(1
      , 1 // //# 05: continued
      , 1 // //# 06: continued
      , y: 1 // //# 07: continued
      , 1 // //# 08: continued
      );
  C.baz(1
      , 1 // //# 09: continued
      , 1 // //# 10: continued
      , y: 1 // //# 11: continued
      , 1 // //# 12: continued
      );
}
