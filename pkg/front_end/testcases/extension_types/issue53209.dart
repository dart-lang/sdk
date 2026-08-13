// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E(int foo) {
  factory E.redirNotEnough() = E; // Error.

  factory E.redirTooMany1(int foo, String bar) = E; // Error.
  factory E.redirTooMany2(int foo, String bar, num baz) = E; // Error.
  factory E.redirTooMany3(int foo, [dynamic bar]) = E; // Error.
  factory E.redirTooMany4(int foo, {required Object bar}) = E; // Error.

  factory E.redirCyclic1(int foo) = E.redirCyclic2; // Error.
  factory E.redirCyclic2(int foo) = E.redirCyclic1; // Error.

  factory E.redirCyclicSelf(int foo) = E.redirCyclicSelf; // Error.
}

extension type GE<X>(X foo) {
  factory GE.redirNotEnough1() = GE; // Error.
  factory GE.redirNotEnough2() = GE.redirNotEnough1; // Should not be reported.
}
