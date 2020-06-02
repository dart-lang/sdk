// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for dartbug.com/35887.
//
// The call specializer inserts a "CheckNull" into main() here, but CheckNull
// was broken in JIT because it didn't create a deopt-info to hold the
// environment in case the it was inside a try/catch block.
//
// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

import 'package:expect/expect.dart';

class Value {
  const Value(this.val);

  final int val;
}

const int limit = 50;

dynamic maybeWrap(int i) => i < limit ? new Value(i) : null;

Future<void> test() async {
  for (int i = 0; i < 60; ++i) {
    if (maybeWrap(i).val == -1) {
      // never mind we just do something with it
      print(i);
    }
  }
}

void main() {
  test().catchError((e) {});
}
