// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field accesses applied to a `dynamic` type are not promoted.
//
// This test illustrates why it's not sound to promote field accesses on
// `dynamic`, even if it appears that the only thing they could possibly resolve
// to is promotable. The soundness can be broken by the presence of *any* class
// containing an implementation of `noSuchMethod` other than the one from
// `Object`.

// SharedOptions=--enable-experiment=inference-update-2

import 'package:expect/expect.dart';

class C {
  final Object? _x;
  C(this._x);
}

class Unrelated {
  Object? _value;

  noSuchMethod(invocation) => _value;
}

main() {
  dynamic d = Unrelated();
  d._value = 0;
  d._x as int; // Succeeds because `Unrelated.noSuchMethod` returns `0`.
  d._value = 'foo';
  // Verify that `d._x` still has type `dynamic` by calling a method that
  // doesn't exist on `int`.
  Expect.equals(1, d._x.indexOf('o'));
}
