// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  const
    factory //# 01: compile-time error
  C()
    = C<C<T>> //# 01: continued
  ;
}

main() {
  const C<int>();
}
