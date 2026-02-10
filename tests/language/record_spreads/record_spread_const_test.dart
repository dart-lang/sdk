// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=record-spreads

/// Test const record spreading.

import "package:expect/expect.dart";

void main() {
  // Const spread of a const record variable.
  const point = (1, 2);
  const colorPoint = (...point, color: 'red');
  Expect.equals(1, colorPoint.$1);
  Expect.equals(2, colorPoint.$2);
  Expect.equals('red', colorPoint.color);

  // Const spread of a const record literal.
  const spread = (...(10, 20), 30);
  Expect.equals(10, spread.$1);
  Expect.equals(20, spread.$2);
  Expect.equals(30, spread.$3);

  // Const spread with named fields.
  const named = (a: 1, b: 2);
  const spreadNamed = (...named, c: 3);
  Expect.equals(1, spreadNamed.a);
  Expect.equals(2, spreadNamed.b);
  Expect.equals(3, spreadNamed.c);

  // Multiple const spreads.
  const x = (1, 2);
  const y = (3, 4);
  const combined = (...x, ...y);
  Expect.equals(1, combined.$1);
  Expect.equals(2, combined.$2);
  Expect.equals(3, combined.$3);
  Expect.equals(4, combined.$4);

  // Const identity: spreading preserves identity.
  const original = (1, 2, name: 'test');
  const viaSpread = (...original);
  Expect.equals(1, viaSpread.$1);
  Expect.equals(2, viaSpread.$2);
  Expect.equals('test', viaSpread.name);
  Expect.identical(original, viaSpread);
}
