// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for bound closures.

import 'package:expect/expect.dart';

typedef int Foo(bool a, [String b]);
typedef int Bar(bool a, [String b]);
typedef int Baz(bool a, {String b});
typedef int Boz(bool a);

class C {
  int foo(bool a, [String b]) => null;
  int baz(bool a, {String b}) => null;
  int boz(bool a, {int b}) => null;
}

main() {
  var c = new C();
  var foo = c.foo;
  Expect.isTrue(foo is Foo, 'foo is Foo');
  Expect.isTrue(foo is Bar, 'foo is Bar');
  Expect.isFalse(foo is Baz, 'foo is Baz');
  Expect.isTrue(foo is Boz, 'foo is Boz');

  var baz = c.baz;
  Expect.isFalse(baz is Foo, 'baz is Foo');
  Expect.isFalse(baz is Bar, 'baz is Bar');
  Expect.isTrue(baz is Baz, 'baz is Baz');
  Expect.isTrue(baz is Boz, 'baz is Boz');

  var boz = c.boz;
  Expect.isFalse(boz is Foo, 'boz is Foo');
  Expect.isFalse(boz is Bar, 'boz is Bar');
  Expect.isFalse(boz is Baz, 'boz is Baz');
  Expect.isTrue(boz is Boz, 'boz is Boz');
}
