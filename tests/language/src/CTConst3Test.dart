// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializers of final fields can be declared out of order.

final P = 2 * (O - N);
final N = 1;
final O = 1 + 3;

int main() {
  Expect.equals(1, N);
  Expect.equals(4, O);
  Expect.equals(6, P);
}
