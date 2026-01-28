// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands can access private extension types in the same library.

import 'package:expect/expect.dart';

extension type _E(int i) {
  static _E get getter => _E(2);
  static _E method() => _E(3);
  _E.named(this.i);
}

typedef Public_E = _E;
final Public_E v = _E(0);

extension type const _ConstE(int i) {
  const _ConstE.named(this.i);
}

typedef Public_ConstE = _ConstE;
const Public_ConstE constV = _ConstE(0);

extension PublicExtensionTypeExtension on Object? {
  _E get asE => v;
}

void check(_E e, int expected) {
  Expect.equals(e.i, expected);
}

void checkConst(_ConstE e, int expected) {
  Expect.equals(e.i, expected);
}

void checkAlias(Public_E e, int expected) {
  Expect.equals(e.i, expected);
}

void checkConstAlias(Public_ConstE e, int expected) {
  Expect.equals(e.i, expected);
}

void main() {
  check(.new(0).asE, 0);
  checkAlias(.new(0).asE, 0);

  check(.new(0), 0);
  checkAlias(.new(0), 0);

  check(.named(1), 1);
  checkAlias(.named(1), 1);

  check(.getter, 2);
  checkAlias(.getter, 2);

  check(.method(), 3);
  checkAlias(.method(), 3);

  check(Public_E(4), 4);
  checkAlias(Public_E(4), 4);

  checkConst(constV, 0);
  checkConstAlias(constV, 0);

  checkConst(const .new(1), 1);
  checkConstAlias(const .new(1), 1);

  checkConst(const .named(2), 2);
  checkConstAlias(const .named(2), 2);

  checkConst(const Public_ConstE(3), 3);
  checkConstAlias(const Public_ConstE(3), 3);
}
