// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for function type alias with a type parameter as result type.
import "package:expect/expect.dart";

typedef bool F<bool>(bool a); // 'bool' is not the boolean type.

bool bar(bool a) {}

int baz(int a) {}

class A<T> {
  T foo(T a) {}
}

main() {
  Expect.isTrue(bar is F);
  Expect.isTrue(baz is F);
  Expect.isTrue(bar is F<bool>);
  Expect.isTrue(baz is F<int>);
  Expect.isTrue(bar is! F<int>);
  Expect.isTrue(baz is! F<bool>);

  var b = new A<bool>();
  var i = new A<int>();
  Expect.isTrue(b.foo is F);
  Expect.isTrue(i.foo is F);
  Expect.isTrue(b.foo is F<bool>);
  Expect.isTrue(i.foo is F<int>);
  Expect.isTrue(b.foo is! F<int>);
  Expect.isTrue(i.foo is! F<bool>);
}
