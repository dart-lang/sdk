// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

foo(a, index) {
  if (a.length < index) {
    for (int i = a.length; i <= index; i++) a.add(i);
  }
  // dart2js was reusing the a.length from above.
  return a[a.length - 1];
}

void main() {
  Expect.equals(3, foo([0], 3));
}
