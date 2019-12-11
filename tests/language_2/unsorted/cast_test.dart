// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

// Test 'expression as Type' casts.

class C {
  final int foo = 42;
}

class D extends C {
  final int bar = 37;
}

Object createC() => new C();
Object createD() => new D();
Object getNull() => null;
Object createList() => <int>[2];
Object createInt() => 87;
Object createString() => "a string";

main() {
  Object oc = createC();
  Object od = createD();
  Object on = getNull();
  Object ol = createList();
  Object oi = createInt();
  Object os = createString();

  Expect.equals(42, (oc as C).foo);
  Expect.equals(42, (od as C).foo);
  Expect.equals(42, (od as D).foo);
  Expect.equals(37, (od as D).bar);
  Expect.equals(37, ((od as C) as D).bar);
  (oc as D).foo; // //# 01: runtime error
  (on as D).toString();
  (on as D).foo; // //# 02: runtime error
  (on as C).foo; // //# 03: runtime error
  oc.foo; // //# 04: compile-time error
  od.foo; // //# 05: compile-time error
  (on as Object).toString();
  (oc as Object).toString();
  (od as Object).toString();
  (on as dynamic).toString();
  (on as dynamic).foo; // //# 07: runtime error
  (oc as dynamic).foo;
  (od as dynamic).foo;
  (oc as dynamic).bar; // //# 08: runtime error
  (od as dynamic).bar;
  C c = oc as C;
  c = od as C;
  c = oc;
  D d = od as D;
  d = oc as D; // //# 10: runtime error
  d = od;

  (ol as List)[0];
  (ol as List<int>)[0];
  (ol as dynamic)[0];
  (ol as String).length; // //# 12: runtime error
  int x = (ol as List<int>)[0];
  (ol as List<int>)[0] = (oi as int);

  (os as String).length;
  (os as dynamic).length;
  (oi as String).length; // //# 13: runtime error
  (os as List).length; // //# 14: runtime error

  (oi as int) + 2;
  (oi as List).length; // //# 15: runtime error
}
