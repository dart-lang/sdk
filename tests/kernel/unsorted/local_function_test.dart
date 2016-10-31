// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of function expressions and function statements.

import 'package:expect/expect.dart';

main() {
  var even;
  odd(n) => n > 0 && even(n - 1);
  even = (n) => n == 0 || odd(n - 1);

  Expect.isTrue(even(0));
  Expect.isTrue(!odd(0));

  Expect.isTrue(odd(1));
  Expect.isTrue(!even(1));

  Expect.isTrue(even(42));
  Expect.isTrue(!odd(42));

  Expect.isTrue(odd(101));
  Expect.isTrue(!even(101));
}
