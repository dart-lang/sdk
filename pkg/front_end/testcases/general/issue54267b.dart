// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum A {
  a(0),
  b(1);

  final int value2;
  const A(this.value);
}

int fn(A a) => switch (a) {
      A.a => 0,
      A.b => 1,
    };
