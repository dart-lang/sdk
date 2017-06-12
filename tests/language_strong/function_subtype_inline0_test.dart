// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping for generic bound closures.

import 'package:expect/expect.dart';

typedef void Foo(bool a, [String b]);
typedef void Bar(bool a, [String b]);
typedef void Baz(bool a, {String b});
typedef int Boz(bool a);

class C<T> {
  void test(String nameOfT, bool expectedResult) {
    Expect.equals(expectedResult, (T a, [String b]) {} is Foo,
        '($nameOfT,[String])->void is Foo');
    Expect.equals(expectedResult, (T a, [String b]) {} is Bar,
        '($nameOfT,[String])->void is Bar');
    Expect.isFalse(
        (T a, [String b]) {} is Baz, '($nameOfT,[String])->void is Baz');
    Expect.equals(expectedResult, (T a, [String b]) {} is Boz,
        '($nameOfT,[String])->void is Boz');

    Expect.isFalse(
        (T a, {String b}) {} is Foo, '($nameOfT,{b:String})->void is Foo');
    Expect.isFalse(
        (T a, {String b}) {} is Bar, '($nameOfT,{b:String})->void is Bar');
    Expect.equals(expectedResult, (T a, {String b}) {} is Baz,
        '($nameOfT,{b:String})->void is Baz');
    Expect.equals(expectedResult, (T a, {String b}) {} is Boz,
        '($nameOfT,{b:String})->void is Boz');
  }
}

main() {
  new C<bool>().test('bool', true);
  new C<int>().test('int', false);
  new C().test('dynamic', true);
}
