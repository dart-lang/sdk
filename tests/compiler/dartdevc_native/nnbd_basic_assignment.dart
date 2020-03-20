// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import 'package:expect/expect.dart';

void main() {
  int x = 42;
  int? y;

  Expect.equals(null, y);
  Expect.throws(() {
    x = y!;
  });
  Expect.equals(42, x);

  y = 17;
  x = y!;
  Expect.equals(17, x);
}
