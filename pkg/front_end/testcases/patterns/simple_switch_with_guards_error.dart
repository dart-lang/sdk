// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  switch (x) {
    case [int a, _] when a.isEven:
    case [_, double a] when a.ceil().isOdd:
      // Error: type of 'a' mismatch.
      return a;
    default:
      return null;
  }
}
