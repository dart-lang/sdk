// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type _E(int i) {
  static _E get getter => _E(0);
  static _E method() => _E(0);
  _E.named(this.i);
}

typedef Public_E = _E;
final Public_E v = _E(0);

extension PublicEExtension on Object? {
  _E get asE => v;
}

extension type const _ConstE(int i) {
  const _ConstE.named(this.i);
}

typedef Public_ConstE = _ConstE;
const Public_ConstE constV = _ConstE(0);

void context(_E e) {}
void contextConst(_ConstE e) {}
void contextAlias(Public_E e) {}
void contextConstAlias(Public_ConstE e) {}
