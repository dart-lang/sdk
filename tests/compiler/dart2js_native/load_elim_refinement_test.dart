// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

class A {
  int a;
}

class B extends A {
  int b;
}

@NoInline()
escape(v) {
  g = v;
}

var g;

main() {
  g = new A();
  var a = JS('returns:A;new:true', '(1,#)', new B());

  a.a = 1;
  if (a is B) {
    escape(a); // Here we need to escape 'a' not the refinement of a to B.
    g.a = 2;
    Expect.equals(2, a.a);
  }
}
