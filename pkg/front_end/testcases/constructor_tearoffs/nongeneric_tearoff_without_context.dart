// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.foo() {}
  A() {}
}

testFoo() => A.foo; // Ok.
testNew() => A.new; // Ok.

testFooExtraArgs() => A<int>.foo; // Error.
testNewExtraArgs() => A<int>.new; // Error.

main() {}
