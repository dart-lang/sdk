// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 11792.

null_() => null;
final Undeclared x = null_(); // null is assignable to x of malformed type.

main() {
  print(x);
}
