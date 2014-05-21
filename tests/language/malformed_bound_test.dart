// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a malformed type variable bound is treated as dynamic.

class C<T
  extends Malformed /// 01: static type warning, runtime error
> {
  f(T t) => t.foo; /// 01: continued
}

main() {
  new C<int>()
    .f(1) /// 01: continued
  ;
}
