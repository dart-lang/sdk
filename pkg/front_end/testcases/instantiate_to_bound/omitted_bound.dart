// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound provides `dynamic` as the type
// argument for those positions in type argument lists of interface types that
// have the bound omitted in the corresponding type parameter, regardless of
// whether the classes that are referred to by the interface types are imported
// from compiled dill libraries or are defined within the source files being
// compiled.

import 'dart:collection';

class A<T> {}

A a;
DoubleLinkedQueue c;

class C {
  A foo() => null;
  DoubleLinkedQueue baz() => null;
}

main() {}
