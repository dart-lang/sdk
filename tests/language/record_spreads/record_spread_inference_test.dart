// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=record-spreads

/// Test type inference with record spreading.

import 'package:expect/static_type_helper.dart';

void main() {
  // Spread preserves exact types.
  var intPair = (1, 2);
  var spread1 = (...intPair, 3);
  spread1.expectStaticType<Exactly<(int, int, int)>>();

  // Spread of named fields preserves types.
  var named = (a: 1, b: 'hello');
  var spread2 = (...named);
  spread2.expectStaticType<Exactly<({int a, String b})>>();

  // Spread of mixed record preserves both positional and named types.
  var mixed = (1, name: 'test');
  var spread3 = (...mixed, 2.0);
  spread3.expectStaticType<Exactly<(int, double, {String name})>>();

  // Downward inference: context type applies to the result.
  (num, num) numPair = (...(1, 2));
  numPair.expectStaticType<Exactly<(num, num)>>();

  // Spread with subtyping: int fields spread into num context.
  var ints = (1, 2);
  (num, num, num) result = (...ints, 3);
  result.expectStaticType<Exactly<(num, num, num)>>();

  // Multiple spreads compose types correctly.
  var pos = (1, 2);
  var namedFields = (x: 3.0, y: 4.0);
  var composed = (...pos, ...namedFields);
  composed.expectStaticType<Exactly<(int, int, {double x, double y})>>();

  // Spread expression type is used, not the variable's declared type.
  (num, num) declaredAsNum = (1, 2);
  var fromDeclared = (...declaredAsNum);
  fromDeclared.expectStaticType<Exactly<(num, num)>>();
}
