// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--omit-explicit-checks

class C {
  final double x;

  C(this.x);

  double getX() => x;
}

void main() {
  final C c = C(0.0);
  int value = c.getX() as int; //# 01: runtime error
  print(value); //# 01: runtime error
}
