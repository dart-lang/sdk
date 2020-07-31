// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/37753.
// A missing piece of transform logic caused nested sync* set to a variable
// to not get transformed, which would either fail an assert or crash.

Iterable<int> getElements() sync* {
  Iterable<int> elements;
  elements = () sync* {
    yield 7;
  }();
  yield* elements;
}

main() => print(getElements());
