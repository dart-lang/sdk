// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class A {
  /*member: A.instanceMethod:deps=[local],direct,explicit=[instanceMethod.T*],needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)]*/
  instanceMethod<T>(t) => t is T;
}

main() {
  /*implicit=[local.T],indirect,needsArgs,selectors=[Selector(call, call, arity=1, types=1)]*/
  local<T>(t) {
    var a = new A();
    a.instanceMethod<T>(t);
  }

  local<int>(0);
}
