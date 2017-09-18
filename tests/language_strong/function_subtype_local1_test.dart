// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for local functions against generic typedefs.

import 'package:expect/expect.dart';

typedef int Foo<T>(T a, [String b]);
typedef int Bar<T>(T a, [String b]);
typedef int Baz<T>(T a, {String b});
typedef int Boz<T>(T a);

main() {
  int foo(bool a, [String b]) => null;
  int baz(bool a, {String b}) => null;

  Expect.isTrue(foo is Foo<bool>, 'foo is Foo<bool>');
  Expect.isTrue(foo is Bar<bool>, 'foo is Bar<bool>');
  Expect.isFalse(foo is Baz<bool>, 'foo is Baz<bool>');
  Expect.isTrue(foo is Boz<bool>, 'foo is Boz<bool>');

  Expect.isFalse(foo is Foo<int>, 'foo is Foo<int>');
  Expect.isFalse(foo is Bar<int>, 'foo is Bar<int>');
  Expect.isFalse(foo is Baz<int>, 'foo is Baz<int>');
  Expect.isFalse(foo is Boz<int>, 'foo is Boz<int>');

  Expect.isTrue(foo is Foo, 'foo is Foo');
  Expect.isTrue(foo is Bar, 'foo is Bar');
  Expect.isFalse(foo is Baz, 'foo is Baz');
  Expect.isTrue(foo is Boz, 'foo is Boz');

  Expect.isFalse(baz is Foo<bool>, 'baz is Foo<bool>');
  Expect.isFalse(baz is Bar<bool>, 'baz is Bar<bool>');
  Expect.isTrue(baz is Baz<bool>, 'baz is Baz<bool>');
  Expect.isTrue(baz is Boz<bool>, 'baz is Boz<bool>');

  Expect.isFalse(baz is Foo<int>, 'baz is Foo<int>');
  Expect.isFalse(baz is Bar<int>, 'baz is Bar<int>');
  Expect.isFalse(baz is Baz<int>, 'baz is Baz<int>');
  Expect.isFalse(baz is Boz<int>, 'baz is Boz<int>');

  Expect.isFalse(baz is Foo, 'baz is Foo');
  Expect.isFalse(baz is Bar, 'baz is Bar');
  Expect.isTrue(baz is Baz, 'baz is Baz');
  Expect.isTrue(baz is Boz, 'baz is Boz');
}
