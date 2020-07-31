// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var x, y;
  // This should cause an error because `x` is final when accessed as an
  // initializing formal.
  A(this.x)
      : y = (() {
          /*@compile-error=unspecified*/ x = 3;
        });
}

main() {}
