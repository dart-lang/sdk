// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/40662.

import "package:expect/expect.dart" show Expect;

bar(int a, List<int> b) {
  Expect.equals(-1, a);
  Expect.equals(-1, (b[0] - 2));
}

foo(int x) async => bar(x - 1, x != null ? [x + 1, x + 2, await null] : null);

void main() async => await foo(0);
