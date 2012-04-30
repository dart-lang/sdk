// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing overridden messageNotUnderstood.

class OverriddenNoSuchMethod {

  OverriddenNoSuchMethod() {}

  noSuchMethod(var function_name, List args) {
    Expect.equals("foo", function_name);
    // 'foo' was called with two parameters (not counting receiver).
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
