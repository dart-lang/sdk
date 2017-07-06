// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class C<E> {
  void sort([int compare(E a, E b)]) {
    /*@typeArgs=C::E*/ sort2(this, compare ?? _compareAny);
  }

  static int _compareAny(a, b) {
    throw 'unimplemented';
  }

  static void sort2<E>(C<E> a, int compare(E a, E b)) {
    throw 'unimplemented';
  }
}

main() {}
