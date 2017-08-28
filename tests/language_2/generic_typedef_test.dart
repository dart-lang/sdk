// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Test runtime behavior of generic function typedefs:
//
// - use "is" and "as" on them.
// - get Type values from runtimeType.
// - pass type parameters from another generic type to them.

typedef A<T> = T Function(T x, T y);
typedef B = T Function<T>(T x, T y);

typedef C<K> = Map<K, V> Function<V>(K k, V v);
typedef D = Map<String, V> Function<V>(String k, V v);

class G<Y, Z> {
  test() {
    dynamic d = (Y x, Y y) => y;
    Expect.isTrue(d is A<Y>);
    Expect.equals(d is A<Z>, Y == Z);

    Expect.isFalse(d is B);
    Expect.throws(() => d as B);

    d = (Y y, Z z) => <Y, Z>{};
    Expect.isFalse(d is C<Y>);

    d = <S>(Y y, S s) => <Y, S>{};
    Expect.isTrue(d is C<Y>);
    Expect.equals(d is C<Z>, Y == Z);
    Expect.equals(d is D, Y == String);
  }
}

main() {
  dynamic d = (int x, int y) => x + y;
  Expect.isTrue(d is A<int>);
  Expect.equals((d as A<int>)(1, 2), 3);

  Expect.isFalse(d is B);
  Expect.throws(() => d as B);

  d = <S>(S x, S y) => x is String ? x : y;
  Expect.isFalse(d is A);
  Expect.throws(() => d as A);

  Expect.isTrue(d is B);
  // TODO(jmesserly): Analyzer incorrectly rejects this form:
  // Expect.equals((d as B)<int>(1, 2), 2);
  B b = d;
  Expect.equals(b<int>(1, 2), 2);
  Expect.equals(b<String>('a', 'b'), 'a');


  new G<int, String>().test();
  new G<String, String>().test();
}
