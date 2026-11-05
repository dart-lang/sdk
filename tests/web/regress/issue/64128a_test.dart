// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for https://dartbug.com/64128
//
// The default value for the override optional parameter was missing from the
// global inference graph. This caused the global inference to conclude that `x`
// in `Chair.check` must be an `int`, and replace the `is` tests with `true`.

import 'package:expect/expect.dart';

class Thing {
  bool check1([Object x = 1]) => x is num;
  bool check2([Object x = 1]) => x is num;
}

class Chair implements Thing {
  @override
  bool check1([Object x = 'furniture']) => x is num;
  @override
  bool check2([Object x = 'furniture']) => x is num;
}

@pragma('dart2js:never-inline')
void test(String name, Thing p) {
  Expect.equals(name == 'Thing', p.check1());
  // Same as default - tests potentially erroneous constant propagation:
  Expect.isTrue(p.check1(1));

  Expect.equals(name == 'Thing', p.check2());
  // Different to default - tests for potentially erroneous type propagation:
  Expect.isTrue(p.check2(200));
}

void main() {
  test('Thing', Thing());
  test('Chair', Chair());
}
