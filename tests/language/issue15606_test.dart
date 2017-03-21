// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {}

var a = [new Object(), 42];

main() {
  while (false) { // Comply to inlining heuristics.
    // Use an unresolved prefix.
    var foo = Unresolved.foo( /// 01: static type warning
      // Make dart2js generate a call to setRuntimeTypeInfo.
      new Foo<int>(), /// 01: continued
      // Use a one-shot interceptor.
      a[0].toString()); /// 01: continued

    // Do an is test on `Foo` to require setRuntimeTypeInfo.
    print(foo is Foo<int>); /// 01: continued
  }
}
