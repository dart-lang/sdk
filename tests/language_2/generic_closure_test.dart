// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check that generic closures are properly instantiated.

import 'package:expect/expect.dart';

typedef T F<T>(T x);
typedef R G<T, R>(T x);

class C<T> {
  get f => (T x) => x;
  T g(T x) => x;
}

main() {
  {
    var c = new C<int>();
    var f = c.f;
    var g = c.g;
    Expect.equals("(int) => int", f.runtimeType.toString()); //# 01: ok
    Expect.equals("(Object) => int", g.runtimeType.toString()); //# 01: ok
    Expect.equals(21, f(21));
    Expect.equals(14, g(14));
    Expect.isTrue(f is Function);
    Expect.isTrue(g is Function);
    Expect.isTrue(f is F);
    Expect.isTrue(g is F);
    Expect.isTrue(f is F<int>);
    Expect.isTrue(g is F<int>);
    Expect.isTrue(f is! F<bool>);
    Expect.isTrue(g is! F<bool>);
    Expect.isTrue(f is G<int, int>);
    Expect.isTrue(g is G<int, int>);
    Expect.isTrue(f is! G<int, bool>);
    Expect.isTrue(g is! G<int, bool>);
    Expect.isTrue(f is! G<Object,int>);
    Expect.isTrue(g is G<Object, int>);
  }

  {
    var c = new C<bool>();
    var f = c.f;
    var g = c.g;
    Expect.equals("(bool) => bool", f.runtimeType.toString()); //# 01: ok
    Expect.equals("(Object) => bool", g.runtimeType.toString()); //# 01: ok
    Expect.isTrue(f is F);
    Expect.isTrue(g is F);
    Expect.isTrue(f is! F<int>);
    Expect.isTrue(g is! F<int>);
    Expect.isTrue(f is F<bool>);
    Expect.isTrue(g is F<bool>);
  }

  {
    var c = new C();
    var f = c.f;
    var g = c.g;
    Expect.equals("(dynamic) => dynamic", f.runtimeType.toString()); //# 01: ok
    Expect.equals("(Object) => dynamic", g.runtimeType.toString()); //# 01: ok
    Expect.isTrue(f is F);
    Expect.isTrue(g is F);
    Expect.isTrue(f is! F<int>);
    Expect.isTrue(g is! F<int>);
    Expect.isTrue(f is! F<bool>);
    Expect.isTrue(g is! F<bool>);
  }
}
