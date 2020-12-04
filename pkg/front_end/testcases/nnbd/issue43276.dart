// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C.gen({int i}); // error

  factory C.fact({int i}) /* error */ {
    return new C.gen();
  }

  factory C.redirect({int i}) = C.gen; // ok
}

class D {}

main() {}
