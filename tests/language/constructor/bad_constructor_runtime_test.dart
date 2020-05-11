// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A constructor can't be static.
class A {

  A();
}

// A factory constructor can't be static.
class B {

  factory B() { return B._(); }

  B._();
}

// A named constructor can have the same name as a setter.
class E {

  E.setter();
}

// A constructor can't be static.
class F {

  F(){}
}

main() {
  new A();
  new B();
  new E.setter();
  new F();
}
