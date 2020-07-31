// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library declares two null-safe classes `B` and `Bq` with members using
// non-nullable types respectively nullable types. The member signatures are
// incompatible (there is no correct override relationship between them in
// any direction), so subtypes can create a conflict by having both as
// superinterfaces, cf. 'legacy_resolves_conflict_2_legacy_lib.dart'.

// Naming conventions: Class `B` has members whose member signatures use
// non-nullable types, and `Bq` has members whose member signatures use
// nullable types (`b` refers to the question marks).

class B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}
