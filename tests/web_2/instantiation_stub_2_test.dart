// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// dart2jsOptions=--strong

import 'package:expect/expect.dart';

List<T> foo<T>([T a1, T a2, T a3, T a4, T a5, T a6, T a7]) =>
    <T>[a1, a2, a3, a4, a5, a6, a7];

class CC {
  List<T> bar<T, U, V>([T a1, T a2, T a3, T a4, T a5, T a6]) =>
      <T>[a1, a2, a3, a4, a5, a6];
}

main() {
  // We expect a call$1$5 entry for foo, accessed nowhere else in the program
  // except via the call$5 entry on the instantiation.
  List<int> Function(int, int, int, int, int) f = foo;
  Expect.equals(4, f(1, 2, 3, 4, 5)[3]);

  // We expect a bar$3$4 entry for bar, accessed nowhere else in the program
  // except via the call$4 entry on the instantiation.
  var o = new CC();
  List<String> Function(String, String, String, String) g = o.bar;
  Expect.equals('abcdnullnull', g('a', 'b', 'c', 'd').join(''));
}
