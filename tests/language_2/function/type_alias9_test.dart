// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for legally self referencing function type alias.

typedef void F(List<G> l);
// [error line 6, column 1, length 26]
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
//           ^
// [cfe] The typedef 'F' has a reference to itself.
typedef void G(List<F> l);
// [error line 11, column 1, length 26]
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF

main() {
  F foo(G g) => g;
  foo(null);
}
