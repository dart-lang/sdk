// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing overridden messageNotUnderstood.

part of OverriddenNoSuchMethodTest.dart;

class GetName {
  foo(a, b) => "foo";
}

String getName(im) => reflect(new GetName()).delegate(im);

class OverriddenNoSuchMethod {
  OverriddenNoSuchMethod() {}

  noSuchMethod(Invocation mirror) {
    Expect.equals("foo", getName(mirror));
    // 'foo' was called with two parameters (not counting receiver).
    List args = mirror.positionalArguments;
    Expect.equals(2, args.length);
    Expect.equals(101, args[0]);
    Expect.equals(202, args[1]);
    return 5;
  }

  static testMain() {
    var obj = new OverriddenNoSuchMethod();
    Expect.equals(5, obj.foo(101, 202));
  }
}
