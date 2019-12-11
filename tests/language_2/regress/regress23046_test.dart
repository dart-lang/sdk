// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Make sure the logic for skipping the initial quotes in a string isn't
// re-triggered after an interpolation expression.

const String x = '$y"';
const String y = 'foo';
const Map m = const {x: 0, y: 1};

main() {
  Expect.equals(x, 'foo"');
  Expect.equals(m.length, 2);
}
