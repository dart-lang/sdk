// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Dart test for testing that strings aren't iterable.

main() {
  var chars = [];
  for (var c in "foo") chars.add(c); /*@compile-error=unspecified*/
}
