// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  C(List<T> x);
}

main() {
  bool b = false;
  List<int> l1 = /*@typeArgs=int*/ [1];
  List<int> l2 = /*@typeArgs=int*/ [2];
  var /*@type=C<int>*/ x = new /*@typeArgs=int*/ C(l1);
  var /*@type=C<int>*/ y = new /*@typeArgs=int*/ C(l2);
  var /*@type=C<int>*/ z = new /*@typeArgs=int*/ C(b ? l1 : l2);
}
