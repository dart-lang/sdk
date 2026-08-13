// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the feature is enabled, types supplied by downward inference
// are preferred over those available via horizontal inference.
//
// The way this happens is that the type parameter is "fixed" after the downward
// inference phase and is not changed in further inference phases.

testProductOfNums(List<num> values) {
  num a = values.fold(1, (p, v) => p * v);
}

main() {}
