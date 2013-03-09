// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that noSuchMethod is resolved in the super class and not in the
// current class.

class C {
  E e = new E();

  bool noSuchMethod(InvocationMirror im) {
    if (im.memberName == 'foo') {
      return im.positionalArguments.isEmpty &&
             im.namedArguments.isEmpty &&
             im.invokeOn(e);
    }
    if (im.memberName == 'bar') {
      return im.positionalArguments.length == 1 &&
             im.namedArguments.isEmpty &&
             im.invokeOn(e);
    }
    if (im.memberName == 'baz') {
      return im.positionalArguments.isEmpty &&
             im.namedArguments.length == 1 &&
             im.invokeOn(e);
    }
    if (im.memberName == 'boz') {
      return im.positionalArguments.length == 1 &&
             im.namedArguments.length == 1 &&
             im.invokeOn(e);
    }
    return false;
  }
}

class D extends C {
  bool noSuchMethod(InvocationMirror im) {
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
