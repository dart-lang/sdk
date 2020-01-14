// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T
    extends Malformed  //# 00: compile-time error
    > {
  f(T t) => t
      .foo  //# 01: compile-time error
      ;
}

main() {
  new C<int>().f(1);
}
