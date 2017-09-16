// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for classes with call functions.

import 'package:expect/expect.dart';

typedef void Foo(bool a, [String b]);
typedef void Bar(bool a, [String b]);
typedef void Baz(bool a, {String b});
typedef void Boz(bool a);

class C1 {
  void call(bool a, [String b]) {}
}

class C2 {
  void call(bool a, {String b}) {}
}

class C3 {
  void call(bool a, {int b}) {}
}

main() {
  Expect.isTrue(new C1() is Foo, 'new C1() is Foo');
  Expect.isTrue(new C1() is Bar, 'new C1() is Bar');
  Expect.isFalse(new C1() is Baz, 'new C1() is Baz');
  Expect.isTrue(new C1() is Boz, 'new C1() is Boz');

  Expect.isFalse(new C2() is Foo, 'new C2() is Foo');
  Expect.isFalse(new C2() is Bar, 'new C2() is Bar');
  Expect.isTrue(new C2() is Baz, 'new C2() is Baz');
  Expect.isTrue(new C2() is Boz, 'new C2() is Boz');

  Expect.isFalse(new C3() is Foo, 'new C3() is Foo');
  Expect.isFalse(new C3() is Bar, 'new C3() is Bar');
  Expect.isFalse(new C3() is Baz, 'new C3() is Baz');
  Expect.isTrue(new C3() is Boz, 'new C3() is Boz');
}
