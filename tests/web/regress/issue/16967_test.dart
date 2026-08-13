// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for http://dartbug.com/16967
// Tests type propagation of negation.

void main() {
  new Foo().test();
}

class Foo {
  var scale = 1;

  void test() {
    var scaleX = scale;
    var scaleY = scale;
    var flipX = true;

    if (flipX) {
      scaleX = -scaleX;
    }

    Expect.equals('X: -1, Y: 1', 'X: $scaleX, Y: $scaleY');
    Expect.equals('true', '${scaleX < 0}', '$scaleX < 0');
    Expect.equals('false', '${scaleY < 0}', '$scaleY < 0');
  }
}
