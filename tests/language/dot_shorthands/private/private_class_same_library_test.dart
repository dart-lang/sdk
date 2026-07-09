// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands can access private classes in the same library.

import 'package:expect/expect.dart';

class _C {
  static _C get getter => _C(3);
  static _C method() => _C(4);
  final int i;
  _C.named(this.i);
  _C(this.i);
}

typedef Public_C = _C;
final Public_C v = _C(0);

class _Const {
  final int i;
  const _Const(this.i);
  const _Const.named(this.i);
}

typedef Public_Const = _Const;
const Public_Const constV = _Const(0);

extension PublicCExtension on Object? {
  _C get asC => v;
}

void check(_C c, int expected) {
  Expect.equals(c.i, expected);
}

void checkAlias(Public_C c, int expected) {
  Expect.equals(c.i, expected);
}

void checkConst(_Const c, int expected) {
  Expect.equals(c.i, expected);
}

void checkConstAlias(Public_Const c, int expected) {
  Expect.equals(c.i, expected);
}

void main() {
  check(.new(1).asC, 0);
  checkAlias(.new(1).asC, 0);

  check(.new(1), 1);
  checkAlias(.new(1), 1);

  check(.named(2), 2);
  checkAlias(.named(2), 2);

  check(.getter, 3);
  checkAlias(.getter, 3);

  check(.method(), 4);
  checkAlias(.method(), 4);

  check(Public_C(5), 5);
  checkAlias(Public_C(5), 5);

  checkConst(constV, 0);
  checkConstAlias(constV, 0);

  checkConst(const .new(1), 1);
  checkConstAlias(const .new(1), 1);

  checkConst(const .named(2), 2);
  checkConstAlias(const .named(2), 2);

  checkConst(const Public_Const(3), 3);
  checkConstAlias(const Public_Const(3), 3);
}
