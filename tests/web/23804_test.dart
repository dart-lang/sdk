// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/23804
//
// Inference incorrectly assumed that `any` and `every` didn't escape the values
// in the collections.

import 'package:expect/expect.dart';

test(n) => n == 1;
bool run(f(dynamic)) => f(1);
main() {
  Expect.equals([test].any(run), true);
}
