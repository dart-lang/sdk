// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E<X, Y> {
  one<int, String>(),
  two<double, num>(),
  three<int, int>.named(42),
  four<num, bool>; // Error.

  const E();
  const E.named(int value);
}

main() {}
