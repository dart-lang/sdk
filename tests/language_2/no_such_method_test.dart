// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that NoSuchMethod is properly called.

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";

class GetName {
  foo({a, b}) => "foo";
  moo({b}) => "moo";
}

String getName(im) => reflect(new GetName()).delegate(im);

class NoSuchMethodTest {
  foo({a: 10, b: 20}) {
    return (10 * a) + b;
  }

  noSuchMethod(Invocation im) {
    Expect.equals("moo", getName(im));
    Expect.equals(0, im.positionalArguments.length);
    Expect.equals(1, im.namedArguments.length);
    return foo(b: im.namedArguments[const Symbol("b")]);
  }

  static testMain() {
    var obj = new NoSuchMethodTest() as dynamic;
    Expect.equals(199, obj.moo(b: 99)); // obj.NoSuchMethod called here.
  }
}

main() {
  NoSuchMethodTest.testMain();
}
