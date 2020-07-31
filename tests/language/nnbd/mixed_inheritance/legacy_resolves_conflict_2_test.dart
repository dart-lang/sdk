// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// Verify that conflicting member signatures are resolved at a legacy
// class `C`, and an opted-in class can extend or implement `C` without
// incurring an error, with and without overriding the conflicting member.

import 'package:expect/expect.dart';
import 'legacy_resolves_conflict_2_legacy_lib.dart';

// Naming convention: Class `De#` extends class `C#` and declares members
// with member signatures using non-nullable types (so `int*` is overridden
// by `int` in various manners). Class `De#q` extends class `C#` and declares
// members with member signatures using nullable types (so `int*` is
// overridden by `int?` in various manners). The abstract class `Di#`
// implements class `C#` and does not declare any members; this just serves
// to ensure that an opted-in class can implement a legacy class with a
// baked-in conflict in its member signatures.

class De0 extends C0 {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class De0q extends C0 {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

abstract class Di0 implements C0 {}

class De1 extends C1 {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class De1q extends C1 {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

abstract class Di1 implements C1 {}

class De2 extends C2 {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class De2q extends C2 {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

abstract class Di2 implements C2 {}

class De3 extends C3 {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class De3q extends C3 {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

abstract class Di3 implements C3 {}

class De4 extends C4 {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class De4q extends C4 {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

abstract class Di4 implements C4 {}

class De5 extends C5 {
  List<int Function(int)> get a => [];
  set a(List<int Function(int)> _) {}
  int Function(int) m(int Function(int) x) => x;
}

class De5q extends C5 {
  List<int? Function(int?)> get a => [];
  set a(List<int? Function(int?)> _) {}
  int? Function(int?) m(int? Function(int?) x) => x;
}

abstract class Di5 implements C5 {}

void main() {
  // Ensure that no class is eliminated by tree-shaking.
  Expect.isNotNull([C0, C1, C2, C3, C4, C5]);
}
