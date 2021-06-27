// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for legally self referencing function type alias.

typedef void F(List<G> l);
//           ^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
// [cfe] The typedef 'F' has a reference to itself.
typedef void G(List<F> l);
//           ^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF

main() {
  F? foo(G? g) => g as F?;
  foo(null);
}
