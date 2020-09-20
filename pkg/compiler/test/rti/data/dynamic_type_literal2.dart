// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: A:explicit=[A*]*/
class A {
  /*member: A.instanceMethod:deps=[B.instanceMethod],exp,needsArgs,selectors=[Selector(call, instanceMethod, arity=0, types=1)]*/
  instanceMethod<T>() => T;
}

class B {
  /*member: B.instanceMethod:needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)]*/
  instanceMethod<T>(A a) => a.instanceMethod<T>();
}

main() {
  var b = new B();
  b.instanceMethod<int>(new A());
}
