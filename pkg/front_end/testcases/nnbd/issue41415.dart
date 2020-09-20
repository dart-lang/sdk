// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {}
test<X extends Null, Y extends Never?, Z extends Never>() {
  // Pre-NNBD bottom type.
  int Function(Null) f = (x) => 1; // Runtime type is int Function(Object?)

  // NNBD bottom type.
  int Function(Never) g = (x) => 1; // Runtime type is int Function(Object?)

  // NNBD bottom type.
  int Function(Never?) h = (x) => 1; // Runtime type is int Function(Object?)

  int Function(String) i = (x) => 1; // Runtime type is int Function(String)

  // Pre-NNBD bottom type.
  int Function(X) j = (x) => 1; // Runtime type is int Function(Object?)

  // NNBD bottom type.
  int Function(Y) k = (x) => 1; // Runtime type is int Function(Object?)

  // NNBD bottom type.
  int Function(Z) l = (x) => 1; // Runtime type is int Function(Object?)

  // NNBD bottom type.
  int Function(Z?) m = (x) => 1; // Runtime type is int Function(Object?)
}
