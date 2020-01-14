// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for top level functions.

import 'package:expect/expect.dart';

typedef int Foo(bool a, [String b]);
typedef int Bar(bool a, [String b]);
typedef int Baz(bool a, {String b});
typedef int Boz(bool a);

int foo(bool a, [String b]) => null;
int baz(bool a, {String b}) => null;
int boz(bool a, {int b}) => null;

main() {
  Expect.isTrue(foo is Foo, 'foo is Foo');
  Expect.isTrue(foo is Bar, 'foo is Bar');
  Expect.isFalse(foo is Baz, 'foo is Baz');
  Expect.isTrue(foo is Boz, 'foo is Boz');

  Expect.isFalse(baz is Foo, 'foo is Foo');
  Expect.isFalse(baz is Bar, 'foo is Bar');
  Expect.isTrue(baz is Baz, 'foo is Baz');
  Expect.isTrue(baz is Boz, 'foo is Boz');

  Expect.isFalse(boz is Foo, 'foo is Foo');
  Expect.isFalse(boz is Bar, 'foo is Bar');
  Expect.isFalse(boz is Baz, 'foo is Baz');
  Expect.isTrue(boz is Boz, 'foo is Boz');
}
