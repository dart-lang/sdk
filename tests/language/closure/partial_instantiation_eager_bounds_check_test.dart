// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test checks that necessary type argument bounds checks are performed
// eagerly during partial instantiation, rather than being delayed until the
// partially instantiated closure is invoked.

import "package:expect/expect.dart";

class C<T> {
  void foo<S extends T>(S x) {}
}

void main() {
  C<Object> c = C<int>();
  void Function(String) fn;
  Expect.throwsTypeError(() {
    fn = c.foo;
  });
}
