// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://code.google.com/p/dart/issues/detail?id=7697.
// dart2js used to optimize [noSuchMethod] based on the user-provided
// argument, and forget that the runtime might call it with its own
// [InvocationMirror] implementation.

class Hey {
  foo() => noSuchMethod(new FakeInvocationMirror());
  noSuchMethod(x) => x;
}

class You extends Hey {
  // We used to think this method is always called with a
  // FakeInvocationMirror instance, but it's also called with the
  // internal mirror implementation.
  noSuchMethod(x) => x.isGetter;
}

class FakeInvocationMirror implements InvocationMirror {
  final bool isGetter = false;
}

main() {
  var x = new Hey();
  Expect.isTrue(x.foo() is FakeInvocationMirror);
  var y = [new You()];
  Expect.isTrue(y[0].bar);
}
