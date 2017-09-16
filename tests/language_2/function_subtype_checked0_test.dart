// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of typedef vs. inlined function types.

import 'package:expect/expect.dart';

typedef int Foo<T>(T a, [String b]);
typedef int Bar<T>(T a, [String b]);
typedef int Baz<T>(T a, {String b});
typedef int Boz<T>(T a);

int fooF(bool a, [String b]) => null;
int bazF(bool a, {String b}) => null;
int bozF(bool a, {int b}) => null;

class C<T> {
  void test1a(Foo<T> f) {}
  void test1b(Bar<T> f) {}
  void test1c(int f(T a, [String b])) {}

  void test2a(Baz<T> f) {}
  void test2b(int f(T a, {String b})) {}

  void test3a(Boz<T> f) {}
  void test3b(int f(T a)) {}

  void test(String nameOfT, bool expectedResult) {
    check(bool expectedResult, f()) {
      if (!expectedResult) {
        Expect.throwsTypeError(f);
      } else {
        f();
      }
    }

    dynamic foo = fooF, baz = bazF, boz = bozF;

    check(expectedResult, () => test1a(foo));
    check(expectedResult, () => test1b(foo));
    check(expectedResult, () => test1b(foo));
    check(false, () => test2a(foo));
    check(false, () => test2b(foo));
    check(expectedResult, () => test3a(foo));
    check(expectedResult, () => test3b(foo));

    check(false, () => test1a(baz));
    check(false, () => test1b(baz));
    check(false, () => test1b(baz));
    check(expectedResult, () => test2a(baz));
    check(expectedResult, () => test2b(baz));
    check(expectedResult, () => test3a(baz));
    check(expectedResult, () => test3b(baz));

    check(false, () => test1a(boz));
    check(false, () => test1b(boz));
    check(false, () => test1b(boz));
    check(false, () => test2a(boz));
    check(false, () => test2b(boz));
    check(expectedResult, () => test3a(boz));
    check(expectedResult, () => test3b(boz));
  }
}

main() {
  new C<bool>().test('bool', true);
  new C<int>().test('int', false);
  new C().test('dynamic', true);
}
