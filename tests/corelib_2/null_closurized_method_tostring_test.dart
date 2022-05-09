// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// The closurized methods of `null` have working `toString()` methods.
// See #48322.

void main() {
  check(null.toString);
  check(null.noSuchMethod);
}

void check(Object o) {
  final s = o.toString();
  Expect.notEquals("", s);
}
