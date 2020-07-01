// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: A:explicit=[A*]*/
class A {
  /*member: A.instanceMethod:deps=[B.instanceMethod],direct,explicit=[instanceMethod.T*],needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)]*/
  instanceMethod<T>(t) => t is T;
}

class B {
  /*member: B.instanceMethod:implicit=[instanceMethod.T],indirect,needsArgs,selectors=[Selector(call, instanceMethod, arity=2, types=1)]*/
  instanceMethod<T>(A a, t) => a.instanceMethod<T>(t);
}

main() {
  var b = new B();
  b.instanceMethod<int>(new A(), 0);
}
