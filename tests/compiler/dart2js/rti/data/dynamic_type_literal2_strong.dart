// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.class: A:explicit=[A]*/
class A {
  /*element: A.instanceMethod:deps=[B.instanceMethod],exp,needsArgs,selectors=[Selector(call, instanceMethod, arity=0, types=1)]*/
  instanceMethod<T>() => T;
}

class B {
  /*element: B.instanceMethod:needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)]*/
  instanceMethod<T>(A a) => a.instanceMethod<T>();
}

main() {
  var b = new B();
  b.instanceMethod<int>(new A());
}
