// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for https://github.com/dart-lang/sdk/issues/42011
main() {
  var a = [];
  // No elements are added, so should not get a ConcurrentModificationError.
  a.addAll(a);
}
