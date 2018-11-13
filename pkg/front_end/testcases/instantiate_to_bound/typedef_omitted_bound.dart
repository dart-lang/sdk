// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound provides `dynamic` as the type
// argument for those positions in type argument lists of typedef types that
// have the bound omitted in the corresponding type parameter.

typedef A<T>(T p);

A a;

class C {
  A foo() => null;
}

main() {}
