// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testImmutable(const []);
  testImmutable(const [1]);
  testImmutable(const [1, 2]);
}

testImmutable(List list) {
  Expect.throwsUnsupportedError(() => list.setRange(0, 0, const []));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, const [], 1));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, const []));
  Expect.throwsUnsupportedError(() => list.setRange(0, 0, []));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, [], 1));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, []));
  Expect.throwsUnsupportedError(() => list.setRange(0, 0, const [1]));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, const [1]));
  Expect.throwsUnsupportedError(() => list.setRange(0, 0, [1]));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, [1]));
  Expect.throwsUnsupportedError(() => list.setRange(0, 1, [1], 1));
}
