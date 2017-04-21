// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:expect/expect.dart';

fact4() {
  var f = 1;
  for (var n in [1, 2, 3, 4]) {
    f *= n;
  }
  return f;
}

fact5() {
  var f = 1, n;
  for (n in [1, 2, 3, 4, 5]) {
    f *= n;
  }
  return f;
}

var global;
fact6() {
  var f = 1;
  for (global in [1, 2, 3, 4, 5, 6]) {
    f *= global;
  }
  return f;
}

main() {
  Expect.isTrue(fact4() == 24);
  Expect.isTrue(fact5() == 120);
  Expect.isTrue(fact6() == 720);
}
