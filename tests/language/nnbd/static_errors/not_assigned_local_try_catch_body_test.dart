// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// It is an error if a potentially non-nullable local variable which has no
// initializer expression and is not marked `late` is used before it is
// definitely assigned.

void main() {
  int v; //# none: compile-time error
  try {
    g();
    v = 0;
  } catch (_) {
    // not assigned
  }
  v;
}

void g() {}
