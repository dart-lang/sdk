// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final results = [];

int invoke(int f()) => f();

class Base {
  var f;
  var z;

  m(x) => results.add(x);

  int g() {
    return 42;
  }
}

class C extends Base {
  final Iterable _iter;

  C(this._iter) {
    _iter.map((x) => super.m(x)).toList();
    super.f = _iter;
    z = invoke(super.g);
  }

  int g() {
    return -1;
  }
}

main() {
  var c = new C([1, 2, 3]);
  Expect.listEquals(results, [1, 2, 3]);
  Expect.listEquals(c.f, [1, 2, 3]);
  Expect.equals(42, c.z);
}
