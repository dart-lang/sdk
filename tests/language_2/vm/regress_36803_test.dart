// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Don't LICM AOT's generic bounds check reference beyond other exception.
// (dartbug.com/36803).
//
// VMOptions=--deterministic --optimization_level=3

import "package:expect/expect.dart";

String var1 = 'Hdi\u{1f600}T';

@pragma('vm:never-inline')
int foo() {
  List<int> a = [1, 2, 3, 4];
  int x = 0;
  do {
    Uri.decodeQueryComponent(var1);
    x = x + a[1000];
  } while (x < 1);
  return x;
}

main() {
  int x = 0;
  try {
    x = foo();
  } on RangeError catch (e) {
    x = -2;
  } on ArgumentError catch (e) {
    x = -1;
  }
  Expect.equals(-1, x);
}
