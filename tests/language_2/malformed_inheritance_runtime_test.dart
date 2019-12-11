// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that malformed types used in extends, implements, and with clauses
// cause compile-time errors.

class A<T> {}

class C

    {
}

class C1

    {
}

class C2

    {
}

class C3

    {
}

class C4

    {
}

class C5

    {
}

class C6<A>

    {
}

class C7<A>

    {
}

class C8<A>

    {
}

class C9<A>

    {
}

class C10<A>

    {
}

class C11<A>

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
