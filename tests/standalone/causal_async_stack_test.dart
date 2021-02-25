// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--lazy-async-stacks

import "package:expect/expect.dart";

noop() async => Future.value(null);

baz() async {
  // Throw exception after the first continuation, when there is no
  // original stack trace.
  await noop();
  throw "Bad!";
}

bar() async {
  await baz();
}

foo() async {
  await bar();
}

main() async {
  try {
    await foo();
  } catch (e, st) {
    Expect.isTrue(st.toString().contains("baz"));
    Expect.isTrue(st.toString().contains("bar"));
    Expect.isTrue(st.toString().contains("foo"));
    Expect.isTrue(st.toString().contains("main"));
  }
}
