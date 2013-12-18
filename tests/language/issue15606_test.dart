// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<T> {}

var a = [new Object(), 42];

main() {
  while (false) { // Comply to inlining heuristics.
    var foo = Unresolved.foo( // Use an unresolved prefix.
      new Foo<int>(), // Make dart2js generate a call to setRuntimeTypeInfo.
      a[0].toString()); // Use a one-shot interceptor.

    // Do an is test on `Foo` to require setRuntimeTypeInfo.
    print(foo is Foo<int>);
  }
}
