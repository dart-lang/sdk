// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for https://github.com/dart-lang/sdk/issues/45631.
// Verifies that compiler doesn't reuse the same Slot for captured local
// variables with the same name and offset.

void main() {
  for (int loc0 in [1]) {
    () {
      ~loc0;
    }.call();
  }
  {
    String loc0 = 'hi';
    () {
      loc0 = 'bye';
    }.call();
  }
}
