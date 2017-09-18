// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not have a function body.

class A {
  var x;
  A(this.x) {}

  // Redirecting constructor must not have a function body.
  A.illegalBody(x) : this(3) {} //     //# 01: compile-time error

  // Redirecting constructor must not initialize any fields.
  A.illegalInit() : this(3), x = 5; // //# 02: compile-time error

  // Redirecting constructor must not have initializing formal parameters.
  A.illegalFormal(this.x) : this(3); // //# 03: compile-time error

  // Redirection constructors must not call super constructor.
  A.illegalSuper() : this(3), super(3); // //# 04: compile-time error
}

main() {
  new A(3);
  new A.illegalBody(10); //        //# 01: continued
  new A.illegalInit(); //        //# 02: continued
  new A.illegalFormal(10); //      //# 03: continued
  new A.illegalSuper(); //       //# 04: continued
}
