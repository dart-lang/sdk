// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

// Regression test for https://github.com/dart-lang/sdk/issues/41939

void checkme0<T>(T? t) {}
void checkme1<T extends dynamic>(T? t) {}
void checkme2<T extends Object?>(T? t) {}
void checkme3<T extends int>(T? t) {}  //# 01: ok

typedef void Test<T>(T? t);

main() {
  Test<int> t0 = checkme0;
  Test<int> t1 = checkme1;
  Test<int> t2 = checkme2;
  Test<int> t3 = checkme3;  //# 01: continued
}
