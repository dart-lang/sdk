// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

foo(x) => x;

check(y) {
  Expect.equals('foo', y);
}

main() {
  var x = foo('foo');
  var y = foo(x);
  x = 'constant';
  check(
      y); // 'y' should not propagate here unless reference to 'x' is rewritten
  foo(x);
  foo(x);
}
