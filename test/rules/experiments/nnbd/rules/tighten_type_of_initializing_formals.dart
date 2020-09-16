// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N tighten_type_of_initializing_formals`

class A {
  A.c1(this.p) : assert(p != null); // LINT
  A.c2(String this.p) : assert(p != null); // OK
  A.c3(this.p); // OK
  A.c4(this.p) : assert(null != p); // LINT
  A.c5(String this.p) : assert(null != p); // OK
  A.c6(
    this.p1, // LINT
    String? p2, // OK
    this.p3, { // OK
    this.p4,  // LINT
    this.p5,  // OK
  }) : assert(p1 != null),
       assert(p2 != null),
       assert(p4 != null);

  String? p;
  String? p1;
  String? p2;
  String? p3;
  String? p4;
  String? p5;
}
