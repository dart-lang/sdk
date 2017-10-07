// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class A {
  int a = -1;

  @NoInline()
  foo(ignored, val) {
    Expect.equals(val, this.a);
  }
}

testA() async {
  var a = new A();
  a.foo(await false, -1);
  a.a = 0;
  a.foo(await false, 0);
}

@NoInline()
@AssumeDynamic()
confuse(x) => x;

class B {
  var f;
  @NoInline()
  var b = 10;
  B(this.f);

  bar(x) => b;
}

foo(x) => 499;
bar(x) => 42;

change(x) {
  x.f = (x) => 99;
}

testB() async {
  var b = confuse(new B(foo));
  Expect.equals(99, b.f(await change(b)));
  var b2 = confuse(new B(bar));
  Expect.equals(10, b2.f(await (b2.f = b2.bar)));
}

test() async {
  await testA();
  await testB();
}

void main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
