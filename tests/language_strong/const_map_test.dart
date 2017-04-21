// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/// Returns its argument.
///
/// Prevents static optimizations and inlining.
confuse(x) {
  // DateTime.now() cannot be predicted statically.
  if (new DateTime.now() == 42) return confuse(2);
  return x;
}

main() {
  // Make sure that const maps use the == operator and not identical. The
  // specification does not explicitly require it, but otherwise ints and
  // Strings wouldn't make much sense as keys.
  var m = const {1: 42, "foo": 499};
  Expect.equals(42, m[confuse(1.0)]);
  Expect.equals(499, m[confuse(new String.fromCharCodes("foo".runes))]);
}
