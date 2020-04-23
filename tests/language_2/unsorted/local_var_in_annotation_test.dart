// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/37065

const x = 0;
main(@x args) {
  const z = 0;
  foo(@z args) {}
  bar(@x args) {}
}
