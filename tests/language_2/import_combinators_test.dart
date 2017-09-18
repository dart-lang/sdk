// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program importing with show/hide combinators.

library importCombinatorsTest;

import "package:expect/expect.dart";
import "import1_lib.dart" show hide, show hide ugly;
import "export1_lib.dart";
import "dart:math" as M show E;

part "import_combinators_part.dart";

main() {
  Expect.equals("hide", hide);
  Expect.equals("show", show);
  // Top-level function from part, refers to imported variable show.
  Expect.equals("show", lookBehindCurtain());
  // Top-level variable E from export1_lib.dart.
  Expect.equals("E", E);
  // Top-level variable E imported from dart:math.
  Expect.equals(2.718281828459045, M.E);
  // Constant LN2 from math library, re-exported by export1_lib.dart.
  Expect.equals(0.6931471805599453, LN2);
}
