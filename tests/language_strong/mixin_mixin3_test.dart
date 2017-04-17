// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class M<T> {
  t() {
    return T;
  }
}

class A<U> = Object with M<List<U>>;

class B0 = Object with A<Set<bool>>;

class B1 = Object with A<Set<int>>;

class C0 extends B0 {}

class C1 extends B1 {}

class A2<K, V> = Object with M<Map<K, V>>;

class B2<V> = Object with A2<Set<V>, List<V>>;

class B3<K, V> = Object with A2<Set<K>, List<V>>;

class C2<T> extends B2<T> {}

class C3<T> extends B3<T, int> {}

class N {
  q() {
    return 42;
  }
}

class O<U> = Object with N;

class P<K, V> = Object with O<V>;

class Q<K, V> extends P<K, V> {}

main() {
  Expect.equals("List<Set<bool>>", new C0().t().toString());
  Expect.equals("List<Set<int>>", new C1().t().toString());
  Expect.equals("Map<Set<bool>, List<bool>>", new C2<bool>().t().toString());
  Expect.equals("Map<Set<bool>, List<int>>", new C3<bool>().t().toString());
  Expect.equals(42, new Q<bool, int>().q());
}
