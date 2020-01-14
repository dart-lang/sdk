// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests showing errors using type-arguments in new expressions:
class A<T> {
  // Can't instantiate type parameter (within static or instance method).



  // OK when used within instance method, but not in static method.
  m3() => new A<T>();

}

main() {
  A a = new A();


  a.m3();

}
