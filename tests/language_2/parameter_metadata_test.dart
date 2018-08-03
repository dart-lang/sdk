// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that metadata annotations can be handled on nested parameters.

test(
     @deprecated //   //# 01: ok
    f(
       @deprecated // //# 02: ok
        a,
       @deprecated // //# 03: ok
        g(
         @deprecated //# 04: ok
            b))) {}

main() {
  test(null);
}
