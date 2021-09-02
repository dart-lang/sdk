// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:exp,needsArgs*/
class A<T> {
  instanceMethod() => A<T>;
}

/*class: B:exp,needsArgs*/
class B<S, T> {
  /*member: B.instanceMethod:
   exp,
   needsArgs,
   selectors=[Selector(call, instanceMethod, arity=0, types=1)]
  */
  instanceMethod<U>() => B<T, U>;
}

main() {
  var a = new A<int>();
  a.instanceMethod();
  var b = new B<int, String>();
  b.instanceMethod<bool>();
}
