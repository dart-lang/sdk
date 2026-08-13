// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

B1 f1() => throw 42;

class A1 {
  var foo = f1(); // Ok.
  A1(this.foo);
}

class B1 extends A1 {
  B1(super.foo) : super();
}

class A2 {
  var foo = B2.new; // Error.
  A2(this.foo);
}

class B2 extends A2 {
  B2(super.foo) : super();
}

class A3 {
  var foo = C3.new; // Error.
  A3();
  A3.initializeFoo(this.foo);
}

class B3 extends A3 {
  var bar = A3.initializeFoo;
  B3(this.bar) : super();
}

class C3 extends B3 {
  C3(super.bar) : super();
}

main() {}
