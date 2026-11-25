// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'extension_scope_test.dart';

import 'extension_scope_lib.dart' show EL1;
import 'extension_scope_lib.dart' as p2 show EL5;

import 'src/lib_p.dart' show p1; // Hide inherited p1 prefix.

part 'extension_scope_part2.dart';

void part1Test() {
  Expect.equals("EL0", L0().name); // Inherited
  Expect.equals("EL1", L1().name); // Imported.
  Expect.equals("EL1", L2().name);
  Expect.equals("EL1", L3().name);
  Expect.equals("EL4", L4().name); // Inherited
  Expect.equals("EL5", L5().name); // Imported
  Expect.equals("EL5", L6().name);

  Expect.equals("EL0", EL0(L6()).name);
  Expect.equals("EL1", EL1(L6()).name);
  Expect.equals("EL5", p2.EL5(L6()).name);
  Expect.equals("p1", p1); // Not a prefix.
}
