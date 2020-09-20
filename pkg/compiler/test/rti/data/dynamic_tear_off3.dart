// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: A:explicit=[A*]*/
class A {
  /*member: A.instanceMethod:deps=[staticMethod],direct,explicit=[instanceMethod.T*],needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)]*/
  instanceMethod<T>(t) => t is T;
}

/*member: staticMethod:implicit=[staticMethod.T],indirect,needsArgs,selectors=[Selector(call, call, arity=2, types=1)]*/
staticMethod<T>(A a, t) => a.instanceMethod<T>(t);

main() {
  var b = staticMethod;
  b<int>(new A(), 0);
}
