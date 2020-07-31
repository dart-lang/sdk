// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Each class defined here has a legacy superinterface as well as a null-safe
// superinterface, thus bringing together legacy and null-safe member
// signatures. Some classes also contain overriding member declarations.
// Each class has a comment indicating the expected member signatures.
// We use this to test whether the resulting member signature is computed
// correctly, cf. 'legacy_resolves_conflict_3{,_error}_test.dart'.

import 'legacy_resolves_conflict_3_legacy_lib.dart';
import 'legacy_resolves_conflict_3_lib.dart';

// Naming conventions: Every class in this library has a name starting with
// `D`, to identify it as belonging to this group: Opted-in, subtype of a
// legacy class.
//
// Every class name ends in a digit, that we designate as `#`. A class whose
// name ends in `#` extends or implements the legacy class `C#`.
//
// The class `DiX#` implements `X` (`i` refers to `implements`). The class
// `DwX#` applies `X` as a mixin (`w` refers to `with`). The class `DiXO#`
// implements `X` and declares overriding members using non-nullable
// types. Class `DiXOq#` implements `X` and declares overriding members using
// nullable types.

// When `C#` is considered to implement `A<int*>` it becomes possible for a
// subtype of `C#` to have a superinterface with members that are compatible
// with the members of `A<int*>`, even in the case where they conflict with
// members of `A<int>`/`A<int?>`, which is actually found in the superinterface
// graph of `C#`. That kind of relationship is created by this library.

// Member signatures: B.
class DiB0 extends C0 implements B {}

// Member signatures: Bq.
class DiBq0 extends C0 implements Bq {}

// Member signatures: B.
class DwB0 extends C0 with B {}

// Member signatures: Bq.
class DwBq0 extends C0 with Bq {}

// Member signatures: B.
class DiBO0 implements C0, B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

// Member signatures: Bq.
class DiBqOq0 implements C0, Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

// Member signatures: B.
class DiB1 extends C1 implements B {}

// Member signatures: Bq.
class DiBq1 extends C1 implements Bq {}

// Member signatures: B.
class DwB1 extends C1 with B {}

// Member signatures: Bq.
class DwBq1 extends C1 with Bq {}

// Member signatures: B.
class DiBO1 implements C1, B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

// Member signatures: Bq.
class DiBqOq1 implements C1, Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

// Member signatures: B.
abstract class DiB2 extends C2 implements B {}

// Member signatures: Bq.
abstract class DiBq2 extends C2 implements Bq {}

// Member signatures: B.
class DwB2 extends C2 with B {}

// Member signatures: Bq.
class DwBq2 extends C2 with Bq {}

// Member signatures: B.
class DiBO2 implements C2, B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

// Member signatures: Bq.
class DiBqOq2 implements C2, Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

// Member signatures: B.
class DiB3 extends C3 implements B {}

// Member signatures: Bq.
class DiBq3 extends C3 implements Bq {}

// Member signatures: B.
class DwB3 extends C3 with B {}

// Member signatures: Bq.
class DwBq3 extends C3 with Bq {}

// Member signatures: B.
class DiBO3 implements C3, B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

// Member signatures: Bq.
class DiBqOq3 implements C3, Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

// Member signatures: B.
class DiB4 extends C4 implements B {}

// Member signatures: Bq.
class DiBq4 extends C4 implements Bq {}

// Member signatures: B.
class DwB4 extends C4 with B {}

// Member signatures: Bq.
class DwBq4 extends C4 with Bq {}

// Member signatures: B.
class DiBO4 implements C4, B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

// Member signatures: Bq.
class DiBqOq4 implements C4, Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

// Member signatures: B.
abstract class DiB5 extends C5 implements B {}

// Member signatures: Bq.
abstract class DiBq5 extends C5 implements Bq {}

// Member signatures: B.
class DwB5 extends C5 with B {}

// Member signatures: Bq.
class DwBq5 extends C5 with Bq {}

// Member signatures: B.
class DiBO5 implements C5, B {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

// Member signatures: Bq.
class DiBqOq5 implements C5, Bq {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}
