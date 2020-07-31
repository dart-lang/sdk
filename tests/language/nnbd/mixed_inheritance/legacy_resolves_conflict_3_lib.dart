// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library declares two null-safe classes `B` and `Bq` with members
// using non-nullable types respectively nullable types. Subtypes having
// either `B` or `Bq` as a superinterface are declared in the library
// 'legacy_resolves_conflict_3_legacy_lib.dart', and the library
// 'legacy_resolves_conflict_3_lib2.dart' declares an override. See the
// comments there for further information.

// Naming convention: Class `B` has member signatures using non-nullable types,
// and `Bq` has member signatures using nullable types (`q` refers to the
// question marks).

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
