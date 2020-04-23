// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  // These are compile time errors for Dart 2.0.
  Expect.throws(() => int.parse("9", radix: 8, /*@compile-error=unspecified*/ onError: "not a function"));
  Expect.throws(() => int.parse("9", radix: 8, /*@compile-error=unspecified*/ onError: () => 42));
  Expect.throws(() => int.parse("9", radix: 8, /*@compile-error=unspecified*/ onError: (v1, v2) => 42));
}
