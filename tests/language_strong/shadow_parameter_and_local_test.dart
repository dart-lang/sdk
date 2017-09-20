// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/29733 in DDC.
foo(a) {
  var a = 123;
  return a;
}

// Regression test for https://github.com/dart-lang/sdk/issues/30792 in DDC.
bar(a) async {
  var a = 123;
  return a;
}

baz(a) sync* {
  var a = 123;
  yield a;
}

qux(a) async* {
  var a = 123;
  yield a;
}

main() async {
  Expect.equals(foo(42), 123);
  Expect.equals(await bar(42), 123);
  Expect.equals(baz(42).single, 123);
  Expect.equals(await qux(42).single, 123);
}
