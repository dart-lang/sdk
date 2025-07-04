// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Formatting can break multitests, so don't format them.
// dart format off

// Check that generic closures are properly instantiated.

import 'package:expect/expect.dart';

typedef T F<T>(T x);
typedef R G<T, R>(T x);

class C<T> {
  get f => (T x) => x;
  T g(T x) => x;
}

Type typeLiteral<T>() => T;

main() {
  {
    var c = new C<int>();
    var f = c.f;
    var g = c.g;
    Expect.equals(typeLiteral<int Function (int)>(), f.runtimeType); //# 01: ok
    Expect.equals(typeLiteral<int Function (Object?)>(), g.runtimeType); //# 01: ok
    Expect.equals(21, f(21));
    Expect.equals(14, g(14));
    Expect.isTrue(f is Function);
    Expect.isTrue(g is Function);
    Expect.isTrue(f is! F);
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
    Expect.equals(typeLiteral<bool Function(bool)>(), f.runtimeType); //# 01: ok
    Expect.equals(typeLiteral<bool Function(Object?)>(), g.runtimeType); //# 01: ok
    Expect.isTrue(f is! F);
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
    Expect.equals(typeLiteral<dynamic Function(dynamic)>(), f.runtimeType); //# 01: ok
    Expect.equals(typeLiteral<dynamic Function(Object?)>(), g.runtimeType); //# 01: ok
    Expect.isTrue(f is F);
    Expect.isTrue(g is F);
    Expect.isTrue(f is! F<int>);
    Expect.isTrue(g is! F<int>);
    Expect.isTrue(f is! F<bool>);
    Expect.isTrue(g is! F<bool>);
  }
}
