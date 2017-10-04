// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs when using a field like a method.

class A {
  var foo;
  A() {
    foo = () {};
  }
  void bar(var a) {
    a.foo();/*@compile-error=unspecified*/ // Tries to invoke the non-existing method 'foo'.
    /*
    'a.foo()' is a "Regular instance-method invocation". The guide says:
    "If no method is found, the result of the invocation expression is
    equivalent to: $0.noSuchMethod(r"id", [$1, ..., $N])."
    Invoking noSuchMethod on an instance of A will invoke Object's
    noSuchMethod (because A doesn't override that method). Object's
    noSuchMethod will throw an error.
    */
  }
}

class FieldMethod4Test {
  static testMain() {
    var a = new A();
    a.bar();/*@compile-error=unspecified*/
  }
}

main() {
  FieldMethod4Test.testMain();
}
