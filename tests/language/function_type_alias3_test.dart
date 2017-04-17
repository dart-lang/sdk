// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test for function type alias with an imported result type that happens
// to have the same name as a type parameter.

library main;

import "package:expect/expect.dart";
import "library11.dart" as lib11;

typedef lib11.Library111<Library111> F<Library111>(
    lib11.Library111<Library111> a, Library111 b);

class A<T> {
  T foo(T a, bool b) {}
}

main() {
  var a = new A<lib11.Library111<bool>>();
  var b = new A<lib11.Library111<int>>();
  Expect.isTrue(a.foo is F);
  Expect.isTrue(a.foo is F<bool>);
  Expect.isTrue(a.foo is! F<int>);
  Expect.isTrue(b.foo is F);
  Expect.isTrue(b.foo is! F<bool>);
  Expect.isTrue(a.foo is! F<int>);
}
