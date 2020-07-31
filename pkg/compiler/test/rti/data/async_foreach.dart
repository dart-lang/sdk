// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: Class:direct,explicit=[Class.T*],implicit=[Class.T],needsArgs*/
/*prod.class: Class:needsArgs*/
class Class<T> {
  method() {
    var list = <T>[];
    // With the `is dynamic Function(Object)` test in the async implementation
    // the closure, with type `dynamic Function(T)`, needs its signature,
    // requiring the need for type arguments on `Class`.
    //
    // This happens because the closure is thought as possibly going to the
    // async.errorHandler callback.
    list.forEach(
        /*needsSignature*/
        (x) => print(x));
  }
}

main() async {
  new Class<int>().method();
}
