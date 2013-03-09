// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

main() {
  Expect.throws(() => 0.0.toStringAsPrecision(0),
                (e) => e is RangeError);
  Expect.throws(() => 0.0.toStringAsPrecision(22),
                (e) => e is RangeError);
  Expect.throws(() => 0.0.toStringAsPrecision(null),
                (e) => e is ArgumentError);
  Expect.throws(() => 0.0.toStringAsPrecision(1.5),
                (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => 0.0.toStringAsPrecision("string"),
                (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => 0.0.toStringAsPrecision("3"),
                (e) => e is ArgumentError || e is TypeError);

}
