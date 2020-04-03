// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int bar(x) => foo(x + 1);
int foo(x) => x > 9 ? x : bar(x);

main() {
  Expect.equals(foo(int.parse("1")), 10);
}
