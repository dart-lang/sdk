// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/22917

import 'package:expect/expect.dart';

m(x) => print('x: $x');

test() => Function.apply(m, []);

main() {
  Expect.throws(test);
}
