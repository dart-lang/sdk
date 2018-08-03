// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Object has a non-trivial constructor and hence cannot be used as mixin.

class S {}

class C0 extends S
with Object //                      //# 01: compile-time error
{}

class C1 = S with Object; //        //# 02: compile-time error

main() {
  new C0();
  new C1(); //                      //# 02: continued
}
