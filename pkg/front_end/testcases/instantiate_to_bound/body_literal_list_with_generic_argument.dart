// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound leaves interface types that have
// their type arguments defined by the programmer intact in cases when those
// interface types are used as type arguments of literal lists that are found in
// method bodies.

class A<T> {}

class B<U> {
  fun() {
    List<A<U>> foo = <A<U>>[];
    List<A<num>> bar = <A<num>>[];
  }
}

main() {}
