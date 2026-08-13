// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--no-minify

import "package:expect/expect.dart";

typedef T Func<T>(T x);

class A<T> {
  final Box<T> box;
  A._(this.box);
  A.foo(Func<T> func) : this._(new Box<T>(func));
}

class Box<T> {
  final Func<T> func;
  Box(this.func);
}

class B extends A {
  B() : super.foo((x) => x);
}

main() {
  var x = new B();
  Expect.equals(x.runtimeType.toString(), 'B');
}
