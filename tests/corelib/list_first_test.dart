// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void test(List list) {
  if (list.isEmpty) {
    Expect.throwsStateError(() => list.first);
  } else {
    Expect.equals(list[0], list.first);
  }
}

main() {
  test([1, 2, 3]);
  test(const ["foo", "bar"]);
  test([]);
  test(const []);
}
