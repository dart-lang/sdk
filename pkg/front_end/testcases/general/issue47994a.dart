// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Const {
  const Const();
}

class BuildAssert {
  const BuildAssert(bool condition, [Object? message])
      : assert(condition, message);
}

const _assert1 = BuildAssert(false);
const _assert2 = BuildAssert(false, null);
const _assert3 = BuildAssert(false, 'foo');
const _assert4 = BuildAssert(false, 0);
const _assert5 = BuildAssert(false, const {});
const _assert6 = BuildAssert(false, #_symbol);
const _assert7 = BuildAssert(false, const Const());

void main() {}
