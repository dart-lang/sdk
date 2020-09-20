// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: staticMethod:deps=[B.instanceMethod],direct,explicit=[staticMethod.T*],needsArgs,selectors=[Selector(call, call, arity=1, types=1)]*/
staticMethod<T>(t) => t is T;

class B {
  /*member: B.instanceMethod:implicit=[instanceMethod.T],indirect,needsArgs,selectors=[Selector(call, instanceMethod, arity=2, types=1)]*/
  instanceMethod<T>(a, t) => a<T>(t);
}

main() {
  var b = new B();
  b.instanceMethod<int>(staticMethod, 0);
}
