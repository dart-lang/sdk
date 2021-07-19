// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.foo() {}
  A() {}
  factory A.bar() => new A();
}

testFoo() => A.foo; // Ok.
testNew() => A.new; // Ok.
testBar() => A.bar; // Ok.

testFooExtraArgs() => A<int>.foo; // Error.
testNewExtraArgs() => A<int>.new; // Error.
testBarExtraArgs() => A<int>.bar; // Error.

main() {}
