// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test for top level declarations involving an imported type.

library main;

import "package:expect/expect.dart";
import "library11.dart" as lib11;

lib11.Library11 variable = null;

lib11.Library11 function() => null;

lib11.Library11 get getter => null;

main() {
  Expect.isTrue(variable == null);
  Expect.isTrue(function() == null);
  Expect.isTrue(getter == null);
}
