// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import "package:expect/expect.dart";

typedef TEST_TYPEDEF<TT extends T Function<T>(T)> = void
    Function<TTT extends TT>();
void testme<TT extends T Function<T>(T)>() {}

main() {
  Expect.isTrue(testme is TEST_TYPEDEF);
  TEST_TYPEDEF ttttt = testme;
  Expect.isTrue(ttttt is TEST_TYPEDEF);
}
