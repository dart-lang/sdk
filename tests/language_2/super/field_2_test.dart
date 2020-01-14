// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:meta/meta.dart" show virtual;

class A {
  @virtual
  var foo;
  A(this.foo);

  B_Sfoo() => 'A.B_Sfoo()';
}

class B extends A {
  B(x) : super(x);

  B_Sfoo() => super.foo;
  BC_Sfoo() => super.foo;
  BCD_Sfoo() => super.foo;
}

class C extends B {
  var foo;
  C(x, this.foo) : super(x);

  BC_Sfoo() => super.foo;
  BCD_Sfoo() => super.foo;
}

class D extends C {
  D(x, y) : super(x, y);

  BCD_Sfoo() => super.foo;
}

var inscrutable;

main() {
  inscrutable = (x) => x;

  var b = new B('Ba');
  var c = new C('Ca', 'Cc');
  var d = new D('Da', 'Dc');

  // Check access via plain getter.
  var b_bc = inscrutable(true) ? b : c; // B, but compiler thinks can also be C
  var c_bc = inscrutable(true) ? c : b; // C, but compiler thinks can also be B

  Expect.equals('Ba', b.foo);
  Expect.equals('Cc', c.foo);
  Expect.equals('Dc', d.foo);
  Expect.equals('Ba', b_bc.foo);
  Expect.equals('Cc', c_bc.foo);

  Expect.equals('Ba', inscrutable(b).foo);
  Expect.equals('Cc', inscrutable(c).foo);
  Expect.equals('Dc', inscrutable(d).foo);
  Expect.equals('Ba', inscrutable(b_bc).foo);
  Expect.equals('Cc', inscrutable(c_bc).foo);

  // Check access via super.foo in various contexts
  Expect.equals('Ba', b.B_Sfoo());
  Expect.equals('Ca', c.B_Sfoo());
  Expect.equals('Da', d.B_Sfoo());

  Expect.equals('Ba', b.BC_Sfoo());
  Expect.equals('Ca', c.BC_Sfoo());
  Expect.equals('Da', d.BC_Sfoo());

  Expect.equals('Ba', b.BCD_Sfoo());
  Expect.equals('Ca', c.BCD_Sfoo());
  Expect.equals('Dc', d.BCD_Sfoo());

  Expect.equals('Ba', inscrutable(b).B_Sfoo());
  Expect.equals('Ca', inscrutable(c).B_Sfoo());
  Expect.equals('Da', inscrutable(d).B_Sfoo());

  Expect.equals('Ba', inscrutable(b).BC_Sfoo());
  Expect.equals('Ca', inscrutable(c).BC_Sfoo());
  Expect.equals('Da', inscrutable(d).BC_Sfoo());

  Expect.equals('Ba', inscrutable(b).BCD_Sfoo());
  Expect.equals('Ca', inscrutable(c).BCD_Sfoo());
  Expect.equals('Dc', inscrutable(d).BCD_Sfoo());
}
