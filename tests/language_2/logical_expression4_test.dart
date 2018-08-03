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

  // The is-checks in the '!' must not be propagated to the if-body.
  // This was a bug in dart2js.
  if (!(o is num && o is num)) {
    Expect.isFalse((nonInlinedNumTypeCheck(o)));
  }
}
