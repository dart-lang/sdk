// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class I<X, Y> {
  final X value;
  I(this.value);
}

void f(I<int, String> i) {}

void main() {
  f(I(2));
}
