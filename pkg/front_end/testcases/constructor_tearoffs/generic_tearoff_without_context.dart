// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  A.foo() {}
  A() {}
}

testFoo() => A.foo; // Ok.
testFooArgs() => A<int>.foo; // Ok.
testNew() => A.new; // Ok.
testNewArgs() => A<int>.new; // Ok.

testFooExtraArgs() => A<int, String>.foo; // Error.
testNewExtraArgs() => A<int, String>.new; // Error.

main() {}
