// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/38467: check that we don't consider
// list[const] to be an access via constant index when list is (potentially)
// a view.

// VMOptions=--optimization_counter_threshold=10 --deterministic

import 'dart:typed_data';

import 'package:expect/expect.dart';

Float64List foo = new Float64List(2);
Float64List bar = new Float64List(2);

void prepare() {
  bar = new Float64List.view(foo.buffer, 8);
}

@pragma('vm:never-inline')
testMain(Float64List xfoo, Float64List xbar) {
  xfoo[1] = 1.0;
  xbar[0] = 2.0;
  return xfoo[1];
}

void main() {
  prepare();
  Expect.equals(2.0, testMain(foo, bar));
}
