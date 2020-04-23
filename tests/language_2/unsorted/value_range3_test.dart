// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  copy(array, index1, index2) {
    if (index1 < index2 + index2) {
      // dart2js used to remove the bounds check.
      return array[index1];
    }
  }
}

main() {
  Expect.throwsRangeError(() => new A().copy(new List(0), 0, 1));
}
