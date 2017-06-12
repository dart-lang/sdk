// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Third dart test program.

import "dart:math";

main() {
  // This should no longer cause a warning because the least-upper-bound
  // of List<int> and Set<int> is Object.
  // The LUB is now EfficientLengthIterable and it extends Iterable.
  var x = (new Random().nextBool() // Unpredictable condition.
          ? <int>[1]
          : new Set<int>.from([1]))
      .first;
  if (x != 1) throw "Wat?";
}
