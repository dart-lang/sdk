// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for generic types.

class GenericsTest<T,V> implements Map<int, int> {
  static int myFunc(bool a, bool b) {
    Expect.equals(true, a);
    Expect.equals(false, b);
    return 42;
  }

  static void testMain() {
    int a = 1;
    int b = 2;
    int c = 3;
    int d = 4;
    Expect.equals(true, a<b);
    Expect.equals(42, myFunc(a<b, c> d));
    Map<int, int> e;
    GenericsTest<int, GenericsTest<int, int>> f;

    takesVoidMethod(void _(int a) {
      Expect.equals(2, a);
      return 99;
    });

    takesGenericMapMethod(Map<int, int> _(int a) {
      Expect.equals(2, a);
      return null;
    });

    takesIntMethod(int _(int a) {
      Expect.equals(2, a);
      return 98;
    });

    e = new Map();
    takesMapMethod(e);
    Expect.equals(2, e[0]);
    Map h = new Map<int, int>();
  }

  static void takesVoidMethod(void f(int a)) {
    Expect.equals(99, f(2));
  }

  static void takesIntMethod(int f(int a)) {
    Expect.equals(98, f(2));
  }

  static void takesGenericMapMethod(Map<int, int> f(int a)) {
    f(2);
  }

  static void takesMapMethod(Map<int, int> m) {
    m[0] = 2;
  }

  Map<int, int> returnMap() {
    return null;
  }
}

class LongGeneric<A, B, C> {
}

class LongerGeneric<A, B, C, D, E, F, G, H, I, J> {
  void func() {
    LongGeneric<String,
                A,
                LongGeneric<C, List<E>, Map<G, Map<I, J>>>> id;

    LongGeneric<
        num,
        Map<int, int>,
        LongGeneric<
            C,
            List<E>,
            Map<G, LongGeneric<I, J, List<A>>>>> id2;
  }
}

main() {
  GenericsTest.testMain();
}
