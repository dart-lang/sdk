// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/76919
// Verifies that we don't try to strengthen an environmentless assertion
// with a class check in AOT mode which crashes AOT compiler.

import 'dart:typed_data';
import 'package:expect/expect.dart';

class C<E, L extends List<E>> {
  final L list;

  C(this.list);

  @pragma('vm:never-inline')
  E operator [](int index) => list[index];

  @pragma('vm:never-inline')
  void operator []=(int index, E value) {
    // We emit AssertAssignable(value, E) on entry.
    // Speculative compilation of this line produces CheckSmi(value)
    list[index] = value;
  }
}

void main(List<String> args) {
  final v = C<int, Uint8List>(Uint8List(1));
  v[0] = 1;
  Expect.equals(1, v[0]);
}
