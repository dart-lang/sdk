// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var a = 'foo';
  for (int i = 0; i < 10; i++) {
    if (i == 0) {
      Expect.isTrue(a === 'foo');
    } else {
      Expect.isTrue(a === 2);
    }
    a = 2;
  }
}
