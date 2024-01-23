// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.instanceMethod:deps=[local],explicit=[instanceMethod.T],needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)],test*/
  instanceMethod<T>(t) => t is T;
}

main() {
  /*implicit=[local.T],needsArgs,selectors=[Selector(call, call, arity=1, types=1)],test*/
  local<T>(t) {
    var a = A();
    a.instanceMethod<T>(t);
  }

  local<int>(0);
}
