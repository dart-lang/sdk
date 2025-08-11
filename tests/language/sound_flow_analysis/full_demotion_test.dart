// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of assignments that fully demote the assigned
// variable when `sound-flow-analysis` is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

import '../static_type_helper.dart';

// If an assignment fully demotes a variable, types of interest are not cleared.
void testFullDemotion(Object x, num n) {
  x as num;
  x.expectStaticType<Exactly<num>>();
  x = '';
  x.expectStaticType<Exactly<Object>>();
  x = n;
  x.expectStaticType<Exactly<num>>();
}

main() {
  testFullDemotion(0, 0);
}
