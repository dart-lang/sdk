// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that the type parameter bounds on tearoffs from generic
// classes are properly instantiated in the signature of the tearoff.

import "package:expect/expect.dart";

class C<T> {
  void foo<S extends T>(S x) {}
}

void foo<S extends int>(S x) {}

void main() {
  dynamic c = C<int>();
  dynamic fn = c.foo;
  Expect.equals("${fn.runtimeType}", "${foo.runtimeType}");
}
