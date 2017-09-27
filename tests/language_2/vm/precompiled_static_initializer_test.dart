// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test optimizations with static fields with precompilation.
// VMOptions=--inlining-hotness=0

import 'package:expect/expect.dart';

init() => 123;

final a = init();

main() {
  var s = 0;
  for (var i = 0; i < 10; i++) {
    s += a;
  }
  Expect.equals(10 * 123, s);
}
