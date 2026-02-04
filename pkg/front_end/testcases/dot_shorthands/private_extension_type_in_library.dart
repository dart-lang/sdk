// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type _E(int x) {
  static _E get getter => _E(1);
  static _E method() => _E(1);
  _E.named(this.x);
}

typedef Public_E = _E;
final Public_E one = _E(1);

extension type const _EConst(int x) {
  const _EConst.named(this.x);
}

typedef Public_EConst = _EConst;
const Public_EConst constOne = _EConst(1);

void test() {
  var x = one;
  x = .new(1); // Ok.
  x = .new; // Error. Can't be assigned, but we're able to use the `_E` type.
  x = .getter; // Ok.
  x = .method(); // Ok.
  x = .named(1); // Ok.
  x = Public_E(1); // Ok.

  var constX = constOne;
  constX = const .new(1); // Ok.
  constX = const .named(1); // Ok.
  constX = const Public_EConst(1); // Ok.
}
