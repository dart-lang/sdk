// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import "implicit_new.dart" as prefix;

class Foo {
  operator +(other) => null;
}

class Bar {
  Bar.named();

  operator +(other) => null;
}

testNSM() {
  var y = prefix.Bar();
  prefix.Bar();
}

f(x) => x;

class IndexTester {
  operator [](_) => null;
  void operator []=(_a, _b) {}
}

main() {
  var x = Foo();
  x = prefix.Foo();
  var z = Bar.named();
  z = prefix.Bar.named();
  f(Foo());
  f(prefix.Foo());
  f(Bar.named());
  f(prefix.Bar.named());
  var l = [Foo(), Bar.named()];
  l = [prefix.Foo(), prefix.Bar.named()];
  var m = {"foo": Foo(), "bar": Bar.named()};
  m = {"foo": prefix.Foo(), "bar": prefix.Bar.named()};
  var i = new IndexTester();
  i[Foo()];
  i[prefix.Foo()];
  i[Bar.named()];
  i[prefix.Bar.named()];
  i[Foo()] = null;
  i[prefix.Foo()] = null;
  i[Bar.named()] = null;
  i[prefix.Bar.named()] = null;
  Foo() + Bar.named();
  prefix.Foo() + prefix.Bar.named();
  Bar.named() + Foo();
  prefix.Bar.named() + prefix.Foo();
}
