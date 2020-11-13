// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  /* bl */ var foo = /*sl:1*/ Foo();
  foo.foo = foo. /*sl:2*/ fooMethod;
  foo /*sl:3*/ .fooMethod();
  // Stepping into this doesn't really work because what it does is something
  // like this:
  // main -> dart.dsend -> dart.callMethod -> get foo ->
  // (back in dart.callMethod) -> dart._checkAndCall -> fooMethod
  // which seems unlikely to be something the user is going to step through.
  // As a "fix" here a breakpoint has been set on the line in fooMethod.
  foo. /*sl:5*/ foo();
}

class Foo {
  void Function() foo;

  void fooMethod() {
    /*bl*/ /*s:4*/ /*s:6*/ print('Hello from fooMethod');
    /*nbb:0:4*/
  }
}
