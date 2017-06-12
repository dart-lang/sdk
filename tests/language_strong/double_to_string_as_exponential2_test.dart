// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 1.0;
  Expect.throws(() => v.toStringAsExponential(-1), (e) => e is RangeError);
  Expect.throws(() => v.toStringAsExponential(21), (e) => e is RangeError);
  Expect.throws(() => v.toStringAsExponential(1.5),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => v.toStringAsExponential("string"),
      (e) => e is ArgumentError || e is TypeError);
  Expect.throws(() => v.toStringAsExponential("3"),
      (e) => e is ArgumentError || e is TypeError);
}
