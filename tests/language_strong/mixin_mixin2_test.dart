// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class M<T> {
  t() {
    return T;
  }
}

class A<U> = Object with M<U>;

class B<V> = Object with A<V>;

class C<U> = Object with M<List<U>>;

class D<V> = Object with C<Set<V>>;

class E extends A<num> {}

class F extends B<String> {}

class G<T> extends C<T> {}

class H<T> extends D<Map<String, T>> {}

main() {
  Expect.equals("num", new E().t().toString());
  Expect.equals("String", new F().t().toString());
  Expect.equals("List<bool>", new G<bool>().t().toString());
  Expect.equals("List<Set<Map<String, int>>>", new H<int>().t().toString());
}
