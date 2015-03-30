// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var exports = 42;

class Foo {
  _foo() => 123;
}

_foo() => 456;

class Frame {
  final List arguments;
  Frame.caller(this.arguments);
  static callee() => null;
}

main() {
  print(exports);
  print(new Foo()._foo());
  print(_foo());
  print(new Frame.caller([1,2,3]));
  var eval = Frame.callee;
  print(eval);
}
