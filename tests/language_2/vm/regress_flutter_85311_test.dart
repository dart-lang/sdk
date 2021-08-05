// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// This is a regression test for the bug in
// https://github.com/flutter/flutter/issues/51828.
// Verifies that temporaries aren't incorrectly assigned types when they're
// reused.

import "package:expect/expect.dart";

bool wasCalled = false;

class Z {
  bool operator ==(Object other) {
    wasCalled = true;
    return true;
  }
}

class Y {
  final dynamic v;
  Y(this.v);
}

Future<bool> crash(dynamic y) async {
  return (y.v == (await 7) || y == (await 9));
}

void main() async {
  await crash(Y(Z()));

  Expect.isTrue(wasCalled);
}
