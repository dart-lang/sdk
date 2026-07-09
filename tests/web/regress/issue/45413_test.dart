// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js stack overflow.

import 'package:expect/expect.dart';

void main() {
  int x = 0;
  do {
    x++;
  } while (x % 10 == 7 ? false : true);
  Expect.equals(7, x);
}
