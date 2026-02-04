// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands can access private mixins in the same library.

import 'package:expect/expect.dart';

mixin _M {
  static _M get getter => _Impl(1);
  static _M method() => _Impl(2);
}

class _Impl with _M {
  final int i;
  _Impl(this.i);
}

typedef Public_M = _M;
final Public_M v = _Impl(0);

void check(_M m, int expected) {
  if (m is _Impl) {
    Expect.equals(m.i, expected);
  } else {
    Expect.fail("m should be _Impl");
  }
}

void checkAlias(Public_M m, int expected) {
  if (m is _Impl) {
    Expect.equals(m.i, expected);
  } else {
    Expect.fail("m should be _Impl");
  }
}

void main() {
  check(v, 0);
  checkAlias(v, 0);

  check(.getter, 1);
  checkAlias(.getter, 1);

  check(.method(), 2);
  checkAlias(.method(), 2);

  check(Public_M.getter, 1);
  checkAlias(Public_M.getter, 1);
}
