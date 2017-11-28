// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://code.google.com/p/dart/issues/detail?id=7697.
// dart2js used to optimize [noSuchMethod] based on the user-provided
// argument, and forget that the runtime might call it with its own
// [Invocation] implementation.

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

class FakeInvocationMirror extends Invocation {
  final bool isGetter = false;
  @override
  bool get isMethod => false;

  @override
  bool get isSetter => false;

  @override
  Symbol get memberName => null;

  @override
  Map<Symbol, dynamic> get namedArguments => {};

  @override
  List get positionalArguments => [];
}

main() {
  var x = new Hey();
  Expect.isTrue(x.foo() is FakeInvocationMirror);
  var y = [new You() as dynamic];
  Expect.isTrue(y[0].bar);
}
