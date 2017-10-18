// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bool nonInlinedNumTypeCheck(Object object) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) {
    return nonInlinedNumTypeCheck(object);
  }
  return object is num;
}

int confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) return confuse(x - 1);
  return x;
}

main() {
  var o = ["foo", 499][confuse(0)];

  // When the lhs of a logical or fails, it must not assume that all negative is
  // checks in it, have failed.
  // Here, the `o is! num` check succeeds, but the length test failed.
  if ((o is! num && o.length == 4) || (nonInlinedNumTypeCheck(o))) { /*@compile-error=unspecified*/
    Expect.fail("Type-check failed");
  }
}
