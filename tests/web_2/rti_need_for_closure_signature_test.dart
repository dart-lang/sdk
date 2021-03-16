// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// User-facing regression test: ensure we correctly record when a closure needs
/// runtime type information for a type parameter that may be used or
/// .runtimeType.

// This test should be run in strong mode to ensure we have not regressed on
// this failure.
class Bar<Q> {
  Q aVar;

  Bar(this.aVar);

  baz(onThing(Q value)) {
    onThing(aVar);
  }
}

foo<T>(Bar<T> bar) {
  bar.baz((T value) {
    print('hi');
  });
}

main() {
  foo<int>(new Bar<int>(3));
}
