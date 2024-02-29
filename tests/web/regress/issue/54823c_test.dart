// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  String a = 'a';

  @pragma('dart2js:never-inline')
  String f(String s) {
    return a = a + s;
  }

  @pragma('dart2js:never-inline')
  String foo(String x) {
    // This expression can be generated as a JavaScript '?:' conditional
    // expression, but should not be on the right side of `this.a += ...`.
    final q = a == x ? f('1') : f('2');
    return a = a + q;
  }

  @pragma('dart2js:never-inline')
  String bar(String x) {
    // This expression can be generated as a JavaScript '?:' conditional
    // expression, but should not be on the right side of `this.a += ... + 'x'`.
    final q = a == x ? f('1') : f('2');
    final r = q + 'x';
    return a = a + r;
  }
}

void main() {
  Expect.equals('a1a1', A().foo('a'));
  Expect.equals('a2a2', A().foo('b'));
  Expect.equals('a1a1x', A().bar('a'));
  Expect.equals('a2a2x', A().bar('b'));
}
