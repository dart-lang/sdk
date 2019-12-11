// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of assigned locals.

class A {
  var a = "a";
}

class B extends A {
  var b = "b";
}

class C extends B {
  var c = "c";
}

class D extends A {
  var d = "d";
}

class E implements C, D {
  var a = "";
  var b = "";
  var c = "";
  var d = "";
}

void main() {
  A a = new E();
  if (a is B) {
    print(a.a);

    a = null;
  }
  if (a is B) {
    a = null;
    print(a.a);

  }
  if (a is B) {
    print(a.a);

    {
      a = null;
    }
    print(a.a);

  }
}
