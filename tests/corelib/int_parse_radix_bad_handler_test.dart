// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  // If handleError isn't an unary function, and it's called, it also throws
  // (either TypeError in checked mode, or some failure in unchecked mode).

  // These are compile time errors for strong mode.
  Expect.throws(() => int.parse("9", radix: 8, onError: "not a function"));
  Expect.throws(() => int.parse("9", radix: 8, onError: () => 42));
  Expect.throws(() => int.parse("9", radix: 8, onError: (v1, v2) => 42));
}
