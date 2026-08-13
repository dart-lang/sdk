// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:compiler/src/util/testing.dart";

/*class: M:checks=[]*/
mixin M<T> {
  t() {
    return T;
  }
}

/*class: A:checks=[],indirectInstance*/
mixin class A<U> = Object with M<U>;

/*class: B:checks=[],indirectInstance*/
class B<V> = Object with A<V>;

/*class: C:checks=[],indirectInstance*/
mixin class C<U> = Object with M<List<U>>;

/*class: D:checks=[],indirectInstance*/
class D<V> = Object with C<Set<V>>;

/*class: E:checks=[],instance*/
class E extends A<num> {}

/*class: F:checks=[],instance*/
class F extends B<String> {}

/*class: G:checks=[],instance*/
class G<T> extends C<T> {}

/*class: H:checks=[],instance*/
class H<T> extends D<Map<String, T>> {}

main() {
  makeLive("num" == E().t().toString());
  makeLive("String" == F().t().toString());
  makeLive("List<bool>" == G<bool>().t().toString());
  makeLive("List<Set<Map<String, int>>>" == H<int>().t().toString());
}
