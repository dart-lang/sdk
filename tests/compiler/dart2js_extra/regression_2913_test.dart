// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var a = 10;
  var b = 11;

  for (var i = 0; i < 1; i++) {
    print('--------');
    print('a $a');
    print('b $b');
    var t = 1;
    if (i < 20) {
      t = 2;
    }

    b = a;
    a = t;
  }
  Expect.equals(2, a);
  Expect.equals(10, b);
}
