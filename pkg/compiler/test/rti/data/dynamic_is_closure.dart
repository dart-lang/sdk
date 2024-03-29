// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  /*member: A.instanceMethod:explicit=[instanceMethod.T],needsArgs,selectors=[Selector(call, instanceMethod, arity=1, types=1)],test*/
  instanceMethod<T>(t) => t is T;
}

main() {
  local() {
    var a = A();
    a.instanceMethod<int>(0);
  }

  local();
}
