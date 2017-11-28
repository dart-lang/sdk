// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";

// Checks that noSuchMethod is resolved in the super class and not in the
// current class.

class C {
  E e = new E();

  bool foo();
  bool bar(int a);
  bool baz({int b});
  bool boz(int a, {int c});

  bool noSuchMethod(Invocation im) {
    if (im.memberName == const Symbol('foo')) {
      return im.positionalArguments.isEmpty &&
          im.namedArguments.isEmpty &&
          reflect(e).delegate(im);
    }
    if (im.memberName == const Symbol('bar')) {
      return im.positionalArguments.length == 1 &&
          im.namedArguments.isEmpty &&
          reflect(e).delegate(im);
    }
    if (im.memberName == const Symbol('baz')) {
      return im.positionalArguments.isEmpty &&
          im.namedArguments.length == 1 &&
          reflect(e).delegate(im);
    }
    if (im.memberName == const Symbol('boz')) {
      return im.positionalArguments.length == 1 &&
          im.namedArguments.length == 1 &&
          reflect(e).delegate(im);
    }
    return false;
  }
}

class D extends C {
  bool noSuchMethod(Invocation im) {
    return false;
  }

  test1() {
    return super.foo();
  }

  test2() {
    return super.bar(1);
  }

  test3() {
    return super.baz(b: 2);
  }

  test4() {
    return super.boz(1, c: 2);
  }
}

class E {
  bool foo() => true;
  bool bar(int a) => a == 1;
  bool baz({int b}) => b == 2;
  bool boz(int a, {int c}) => a == 1 && c == 2;
}

main() {
  var d = new D();
  Expect.isTrue(d.test1());
  Expect.isTrue(d.test2());
  Expect.isTrue(d.test3());
  Expect.isTrue(d.test4());
}
