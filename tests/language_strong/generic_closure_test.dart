// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check that generic closures are properly instantiated.

import 'package:expect/expect.dart';

typedef T F<T>(T x);
typedef R G<T, R>(T x);

class C<T> {
  get f => (T x) => 2 * x;
  T g(T x) => 3 * x;
}

main() {
  var c = new C<int>();
  var f = c.f;
  var g = c.g;
  Expect.equals(42, f(21));
  Expect.equals(42, g(14));
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
  Expect.isTrue(f is G<int, bool>);
  Expect.isTrue(g is! G<int, bool>);
  Expect.equals("(int) => dynamic", f.runtimeType.toString());
  Expect.equals("(int) => int", g.runtimeType.toString());

  c = new C<bool>();
  f = c.f;
  g = c.g;
  Expect.isTrue(f is F);
  Expect.isTrue(g is F);
  Expect.isTrue(f is! F<int>);
  Expect.isTrue(g is! F<int>);
  Expect.isTrue(f is F<bool>);
  Expect.isTrue(g is F<bool>);
  Expect.equals("(bool) => dynamic", f.runtimeType.toString());
  Expect.equals("(bool) => bool", g.runtimeType.toString());

  c = new C();
  f = c.f;
  g = c.g;
  Expect.isTrue(f is F);
  Expect.isTrue(g is F);
  Expect.isTrue(f is F<int>);
  Expect.isTrue(g is F<int>);
  Expect.isTrue(f is F<bool>);
  Expect.isTrue(g is F<bool>);
  Expect.equals("(dynamic) => dynamic", f.runtimeType.toString());
  Expect.equals("(dynamic) => dynamic", g.runtimeType.toString());
}
