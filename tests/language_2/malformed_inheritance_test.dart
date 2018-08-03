// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that malformed types used in extends, implements, and with clauses
// cause compile-time errors.

class A<T> {}

class C
    extends Unresolved  //# 00: compile-time error
    {
}

class C1
    extends A<Unresolved>  //# 01: compile-time error
    {
}

class C2
    extends Object with Unresolved  //# 02: compile-time error
    {
}

class C3
    extends Object with A<Unresolved>  //# 03: compile-time error
    {
}

class C4
    implements Unresolved   //# 04: compile-time error
    {
}

class C5
    implements A<Unresolved>   //# 05: compile-time error
    {
}

class C6<A>
    extends A<int>   //# 06: compile-time error
    {
}

class C7<A>
    extends A<Unresolved>   //# 07: compile-time error
    {
}

class C8<A>
    extends Object with A<int>   //# 08: compile-time error
    {
}

class C9<A>
    extends Object with A<Unresolved>   //# 09: compile-time error
    {
}

class C10<A>
    implements A<int>   //# 10: compile-time error
    {
}

class C11<A>
    implements A<Unresolved>   //# 11: compile-time error
    {
}

void main() {
  new C();
  new C1();
  new C2();
  new C3();
  new C4();
  new C5();
  new C6<Object>();
  new C7<Object>();
  new C8<Object>();
  new C9<Object>();
  new C10<Object>();
  new C11<Object>();
}
