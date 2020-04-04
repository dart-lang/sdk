// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test cases where the syntax is ambiguous between maps and sets when control
// flow elements contain spreads.
import 'dart:collection';

import 'utils.dart';

void main() {
  Map<int, int> map = {};
  Set<int> set = Set();
  dynamic dyn = map;
  Iterable<int> iterable = [];
  CustomSet customSet = CustomSet();
  CustomMap customMap = CustomMap();

  var _ = {if (true) ...dyn}; //# 00: compile-time error
  var _ = {if (true) ...map else ...set}; //# 01: compile-time error
  var _ = {if (true) ...map else ...iterable}; //# 02: compile-time error
  var _ = {if (true) ...map else ...customSet}; //# 03: compile-time error
  var _ = {if (true) ...set else ...customMap}; //# 04: compile-time error
  var _ = {if (true) ...dyn else ...dyn}; //# 05: compile-time error
  var _ = {if (true) ...iterable else ...customMap}; //# 06: compile-time error
  var _ = {if (true) ...customSet else ...customMap}; //# 07: compile-time error

  var _ = {for (; false;) ...dyn}; //# 08: compile-time error
  var _ = {for (; false;) ...map, ...set}; //# 09: compile-time error
  var _ = {for (; false;) ...map, ...iterable}; //# 10: compile-time error
  var _ = {for (; false;) ...map, ...customSet}; //# 11: compile-time error
  var _ = {for (; false;) ...set, ...customMap}; //# 12: compile-time error
  var _ = {for (; false;) ...dyn, ...dyn}; //# 13: compile-time error
  var _ = {for (; false;) ...iterable, ...customMap}; //# 14: compile-time error
  var _ = {for (; false;) ...customSet, ...customMap}; //# 15: compile-time error
}
