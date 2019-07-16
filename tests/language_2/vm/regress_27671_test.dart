// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable_asserts --enable-inlining-annotations --optimization-counter-threshold=10 --no-background-compilation

import 'package:expect/expect.dart';
import 'regress_27671_other.dart';

const AlwaysInline = "AlwaysInline";
const NeverInline = "NeverInline";

@AlwaysInline
bounce(x) {
  for (int i = 0; i < 10; i++) {
    check(f, x);
  }
}

@AlwaysInline
bool f(y) => y > 0;

main() {
  for (int i = 0; i < 100; i++) {
    bounce(1);
  }
  try {
    bounce(-1);
  } catch (e) {
    Expect.isTrue(e.toString().contains('f(x) && true'));
  }
}
