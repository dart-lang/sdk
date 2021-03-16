// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// Test that optional arguments of methods with a generator are forwarded
/// properly when optional parameters are elided.
///
/// This is a regression test for issue #35924
import "package:expect/expect.dart";

// The type parameter forces us to create a generator body. The call from the
// method to the body needs to correctly handle elided parameters.
Future<T> foo<T>(T Function(int, int, int) toT,
    {int p1: 0, int p2: 1, int p3: 2}) async {
  await null;
  return toT(p1, p2, p3);
}

main() async {
  Expect.equals(await foo<String>((a, b, c) => "$a $b $c", p2: 4), "0 4 2");
}
