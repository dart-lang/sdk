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

extension PublicCExtension on Object? {
  _C get asC => v;
}
