// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> {
  C(List<T> x);
}

main() {
  bool b = false;
  List<int> l1 = [1];
  List<int> l2 = [2];
  var x = new C(l1);
  var y = new C(l2);
  var z = new C(b ? l1 : l2);
}
