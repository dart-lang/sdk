// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: Class:direct,explicit=[Class.T*],implicit=[Class.T],needsArgs*/
class Class<T> {
  method() {
    var list = <T>[];
    // If any method was `async`, this would have triggered the need for type
    // arguments on `Class`. See the 'async_foreach.dart' test.
    list.forEach(
        /*spec.needsSignature*/
        (x) => print(x));
  }
}

main() {
  new Class<int>().method();
}
