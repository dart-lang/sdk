// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library panda_test;

import "package:expect/expect.dart";
import 'panda_lib.dart' as p;

void main() {
  p.Panda x = new p.Panda();
  Expect.isTrue(x is p.Panda);
  x = null;
  Expect.isFalse(x is p.Panda);
}
