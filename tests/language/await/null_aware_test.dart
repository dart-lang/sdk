// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue dartbug.com/24392

import 'package:expect/expect.dart';
import 'dart:async';

Future<int?> f() async {
  // Unreachable.
  Expect.isTrue(false);
}

main() async {
  var x = 1 as int?;
  x ??= await f();
  Expect.equals(1, x);

  var y = 1 as int?;
  y = y ?? await f();
  Expect.equals(1, y);
}
