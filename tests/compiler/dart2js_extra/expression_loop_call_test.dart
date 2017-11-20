// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for [ClosureCallSiteTypeInformation] in loops.

class Class<T> {
  method() {
    for (var a in []) {
      (T)(); //# 01: ok
      (Object)(); //# 02: ok
      (this)(); //# 03: ok
      (1)(); //# 04: ok
    }
  }
}

main() {
  new Class().method();
}
