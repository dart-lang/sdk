// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is language-defined `Iterable` or `Stream`.

// SharedOptions=--enable-experiment=enum-shorthands

void main() async {
  var iter = [1, 2];
  for (var x in .castFrom(iter)) {
    print(x);
  }
  await for (var x in .fromIterable(iter)) {
    print(x);
  }
}
