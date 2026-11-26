// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// In each file, prefixes are looked up before unprefixed imports, and a
// part inherits both from its parent file in that order. So the prefix 'p1'
// shadows the imported getter 'p1' here, in the part and in its sub-part.

import 'package:expect/expect.dart';

import 'src/lib_p.dart' show p1;
import 'src/lib_x.dart' as p1 show x1;

part 'prefix_shadows_import_part1.dart';

void main() {
  Expect.equals('x1', p1.x1);
  Expect.equals('x1', inPart1());
  Expect.equals('x1', inPart2());
}
