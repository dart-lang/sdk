// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// Check that the `main` function can be defined in a part of a part.

// Contains three parts which imports different extensions.
// *test.dart  -
// - *part1.dart
//   - *part2.dart
// - *part3.dart

import 'package:expect/expect.dart';

import 'extension_scope_lib.dart' show EL0, L0, L1, L2, L3, L4, L5, L6;
import 'extension_scope_lib.dart' as p1 show EL4;

part 'extension_scope_part1.dart';
part 'extension_scope_part3.dart';

void main() {
  // Only EL0 and EL4 available.
  Expect.equals("EL0", L0().name);
  Expect.equals("EL0", L1().name);
  Expect.equals("EL0", L2().name);
  Expect.equals("EL0", L3().name);
  Expect.equals("EL4", L4().name);
  Expect.equals("EL4", L5().name);
  Expect.equals("EL4", L6().name);

  Expect.equals("EL0", EL0(L6()).name);
  Expect.equals("EL4", p1.EL4(L6()).name);

  part1Test();
  part2Test();
  part3Test();
}
