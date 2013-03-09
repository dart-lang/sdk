// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T> {}

sameType(a, b) {
  Expect.equals(a.runtimeType, b.runtimeType);
}

differentType(a, b) {
  Expect.isFalse(a.runtimeType == b.runtimeType);
}

main() {
  // Test types obtained by calling runtimeType.
  var v1 = new C<int>();
  var v2 = new C<int>();
  sameType(v1, v2);

  var v3 = new C<num>();
  differentType(v1, v3);

  var i = 1;
  var s = 'string';
  var d = 3.14;
  var b = true;
  sameType(2, i);
  sameType('hest', s);
  sameType(1.2, d);
  sameType(false, b);

  var l = [1, 2, 3];
  var m = {'a': 1, 'b': 2};
  sameType([], l);
  sameType({}, m);

  // Test parameterized lists.
  sameType(new List<int>(), new List<int>());
  differentType(new List<int>(), new List<num>());
  differentType(new List<int>(), new List());
}
