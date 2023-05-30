// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=records,patterns

import "package:expect/expect.dart";

void main() {
  dynamic foo = 84;
  var (int x, (int, )? y) = switch (foo) {
    _ => (42, null),
  };
  Expect.equals(42, x);
  Expect.equals(null, y);
}

