// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for top level functions.

import 'package:expect/expect.dart';

typedef int Foo<T>(T a, [String b]);
typedef int Bar<T>(T a, [String b]);
typedef int Baz<T>(T a, {String b});
typedef int Boz<T>(T a);

int foo(bool a, [String b]) => null;
int baz(bool a, {String b}) => null;
int boz(bool a, {int b}) => null;

class C<T> {
  void test(String nameOfT, bool expectedResult) {
    Expect.equals(expectedResult, foo is Foo<T>, 'foo is Foo<$nameOfT>');
    Expect.equals(expectedResult, foo is Bar<T>, 'foo is Bar<$nameOfT>');
    Expect.isFalse(foo is Baz<T>, 'foo is Baz<$nameOfT>');
    Expect.equals(expectedResult, foo is Boz<T>, 'foo is Boz<$nameOfT>');

    Expect.isFalse(baz is Foo<T>, 'foo is Foo<$nameOfT>');
    Expect.isFalse(baz is Bar<T>, 'foo is Bar<$nameOfT>');
    Expect.equals(expectedResult, baz is Baz<T>, 'foo is Baz<$nameOfT>');
    Expect.equals(expectedResult, baz is Boz<T>, 'foo is Boz<$nameOfT>');

    Expect.isFalse(boz is Foo<T>, 'foo is Foo<$nameOfT>');
    Expect.isFalse(boz is Bar<T>, 'foo is Bar<$nameOfT>');
    Expect.isFalse(boz is Baz<T>, 'foo is Baz<$nameOfT>');
    Expect.equals(expectedResult, boz is Boz<T>, 'foo is Boz<$nameOfT>');
  }
}

main() {
  new C<bool>().test('bool', true);
  new C<int>().test('int', false);
  new C().test('dynamic', true);
}
