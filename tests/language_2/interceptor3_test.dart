// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that code motion in the presence of interceptors work in dart2js.

main() {
  var a = <dynamic>[2, '2'];
  var b = a[1];
  if (a[0] == 2 && b is String) {
    Expect.isTrue(b.contains('2'));
  } else {
    b.isEven();
  }
}
