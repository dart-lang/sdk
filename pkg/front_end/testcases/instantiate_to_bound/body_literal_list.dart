// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound provides type arguments to raw
// interface types that are themselves used as type arguments of literal lists
// found in method bodies.

class A<T extends num> {}

class B {
  foo() {
    var a = <A>[];
  }
}

main() {
  var a = <A>[];
}
