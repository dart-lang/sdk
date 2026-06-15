// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Primary constructors are enabled by default.

import 'package:expect/expect.dart';

class Point(var int x, var int y);

void main() {
  var p = Point(1, 2);
  Expect.equals(p.x, 1);
  Expect.equals(p.y, 2);
}
