// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A<T> {
  void f<U>(Map<T, U> m) {}
}

class B extends A<String> {
  // To see that this is a valid override, both T and U need to be substituted
  // correctly.
  void f<V>(Map<String, V> m) {}
}

main() {}
