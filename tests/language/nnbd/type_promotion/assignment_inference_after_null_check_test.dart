// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The reason that `if (x == null)` doesn't promote x's type to `Null` is
// because we lose type argument information that would be necessary for
// inference.  This test makes sure that the type argument information is
// appropriately preserved.

// SharedOptions=--enable-experiment=non-nullable

void f(List<int>? x) {
  if (x == null) {
    // If x were promoted to `Null`, inference would not know that `[]` should
    // be considered to mean `<int>[]`, so either the line below would be a
    // compile-time error, or a runtime error would occur later when we try to
    // add an int to the list.
    x = [];
  }
  x.add(0);
}

main() {
  f(null);
}
