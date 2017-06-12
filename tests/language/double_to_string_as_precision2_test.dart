// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 0.0;
  Expect.throws(() => v.toStringAsPrecision(0), (e) => e is RangeError);
  Expect.throws(() => v.toStringAsPrecision(22), (e) => e is RangeError);
  Expect.throws(() => v.toStringAsPrecision(null), (e) => e is ArgumentError);
  Expect.throws(() => v.toStringAsPrecision(1.5),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => v.toStringAsPrecision("string"),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => v.toStringAsPrecision("3"),
      (e) => e is ArgumentError || e is TypeError);
}
