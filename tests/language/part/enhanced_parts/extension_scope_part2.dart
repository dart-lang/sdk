// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'extension_scope_part1.dart';

import 'extension_scope_lib.dart' show EL2;
import 'extension_scope_lib.dart' as p1 show EL6;

void part2Test() {
  Expect.equals("EL0", L0().name);
  Expect.equals("EL1", L1().name);
  Expect.equals("EL2", L2().name);
  Expect.equals("EL2", L3().name);
  Expect.equals("EL4", L4().name);
  Expect.equals("EL5", L5().name);
  Expect.equals("EL6", L6().name);

  Expect.equals("EL0", EL0(L6()).name);
  Expect.equals("EL1", EL1(L6()).name);
  Expect.equals("EL2", EL2(L6()).name);
  Expect.equals("EL5", p2.EL5(L6()).name);
  Expect.equals("EL6", p1.EL6(L6()).name);
}
