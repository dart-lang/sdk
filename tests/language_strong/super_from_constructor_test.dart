// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final results = [];

class Base {
  var f;
  m(x) => results.add(x);
}

class C extends Base {
  final Iterable _iter;

  C(this._iter) {
    _iter.map((x) => super.m(x)).toList();
    super.f = _iter;
  }
}

main() {
  var c = new C([1, 2, 3]);
  Expect.listEquals(results, [1, 2, 3]);
  Expect.listEquals(c.f, [1, 2, 3]);
}
