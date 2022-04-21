// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart'
    show $0, $9, $A, $Z, $_, $a, $z;

/// Returns an infinite sequence of property names in increasing size.
Iterable<String> generalMinifiedNameSequence() sync* {
  List<int> nextName = [$a];

  /// Increments the letter at [pos] in the current name. Also takes care of
  /// overflows to the left. Returns the carry bit, i.e., it returns `true`
  /// if all positions to the left have wrapped around.
  ///
  /// If [nextName] is initially 'a', this will generate the sequence
  ///
  ///     [a-zA-Z_]
  ///     [a-zA-Z_][0-9a-zA-Z_]
  ///     [a-zA-Z_][0-9a-zA-Z_][0-9a-zA-Z_]
  ///     ...
  bool incrementPosition(int pos) {
    bool overflow = false;
    if (pos < 0) return true;
    int value = nextName[pos];
    if (value == $9) {
      value = $a;
    } else if (value == $z) {
      value = $A;
    } else if (value == $Z) {
      value = $_;
    } else if (value == $_) {
      overflow = incrementPosition(pos - 1);
      value = (pos > 0) ? $0 : $a;
    } else {
      value++;
    }
    nextName[pos] = value;
    return overflow;
  }

  while (true) {
    yield String.fromCharCodes(nextName);
    if (incrementPosition(nextName.length - 1)) {
      nextName.add($0);
    }
  }
}
