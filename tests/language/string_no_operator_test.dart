// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var x = "x";
  var y = "y";
  Expect.throws(() => x < y);
  Expect.throws(() => x <= y);
  Expect.throws(() => x > y);
  Expect.throws(() => x >= y);
  Expect.throws(() => x - y);
  Expect.throws(() => x * y);
  Expect.throws(() => x / y);
  Expect.throws(() => x ~/ y);
  Expect.throws(() => x % y);
  Expect.throws(() => x >> y);
  Expect.throws(() => x << y);
  Expect.throws(() => x & y);
  Expect.throws(() => x | y);
  Expect.throws(() => x ^ y);
  Expect.throws(() => -x);
  Expect.throws(() => ~x);
}
