// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  A.foo() {}
  A() {}
  factory A.bar() => new A<X>();
}

testFoo() => A.foo; // Ok.
testFooArgs() => A<int>.foo; // Ok.
testNew() => A.new; // Ok.
testNewArgs() => A<int>.new; // Ok.
testBar() => A.bar; // Ok.
testBarArgs() => A<int>.bar; // Ok.

testFooExtraArgs() => A<int, String>.foo; // Error.
testNewExtraArgs() => A<int, String>.new; // Error.
testBarExtraArgs() => A<int, String>.bar; // Error.

method() {
  var foo = A.foo; // Ok.
  var fooArgs = A<int>.foo; // Ok.
  var _new = A.new; // Ok.
  var newArgs  = A<int>.new; // Ok.
  var bar = A.bar; // Ok.
  var barArgs = A<int>.bar; // Ok.

  var fooExtraArgs = A<int, String>.foo; // Error.
  var newExtraArgs = A<int, String>.new; // Error.
  var barExtraArgs = A<int, String>.bar; // Error.
}

main() {}
