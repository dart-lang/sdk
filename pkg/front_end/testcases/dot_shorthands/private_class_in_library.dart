// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _C {
  static _C get getter => _C();
  static _C method() => _C();
  _C.named();
  _C();
}

typedef Public_C = _C;
final Public_C v = _C();

class _Const {
  const _Const();
  const _Const.named();
}

typedef Public_Const = _Const;
const Public_Const constV = _Const();

void test() {
  var w = v;
  w = .new(); // Ok.
  w = .new; // Error. Can't be assigned, but we're able to use the `_C` type.
  w = .getter; // Ok.
  w = .method(); // Ok.
  w = .named(); // Ok.
  w = Public_C(); // Ok.

  var constW = constV;
  constW = const .new(); // Ok.
  constW = const .named(); // Ok.
  constW = const Public_Const(); // Ok.
}
