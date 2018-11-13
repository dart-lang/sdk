// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that TypeErrors happen for async methods without using returned Future.

import 'dart:async';
import 'package:expect/expect.dart';

class D<T> {
  // Parametric covariance check is usually compiled into method.
  Future<T> add(T n) async {
    return n;
  }
}

main() async {
  D<num> d = new D<int>();
  Expect.throwsTypeError(() => d.add(4.6));
}
