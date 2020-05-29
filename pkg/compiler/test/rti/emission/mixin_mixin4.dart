// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

/*class: I:checkedInstance*/
class I<T> {}

/*class: J:checkedInstance*/
class J<T> {}

/*class: S:checkedInstance,checks=[],indirectInstance*/
class S<T> {}

/*class: M:checkedInstance,checks=[]*/
class M<T> {
  t() {
    return T;
  }
}

/*class: A:checkedInstance*/
class A<U, V> = Object with M<Map<U, V>> implements I<V>;

/*class: C:checks=[$isA,$isI,$isJ],instance*/
class C<T, K> = S<T> with A<T, List<K>> implements J<K>;

@pragma('dart2js:noInline')
test(c) {
  Expect.equals("Map<int, List<bool>>", c.t().toString());
  Expect.isTrue(c is I<List<bool>>);
  Expect.isTrue(c is J<bool>);
  Expect.isTrue(c is S<int>);
  Expect.isTrue(c is A<int, List<bool>>);
  Expect.isTrue(c is M<Map<int, List<bool>>>);
}

main() {
  test(new C<int, bool>());
}
