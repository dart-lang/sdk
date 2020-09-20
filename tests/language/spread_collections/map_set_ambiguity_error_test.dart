// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test cases where the syntax is ambiguous between maps and sets.
import 'dart:collection';

import 'helper_classes.dart';

void main() {
  Map<int, int> map = {};
  Set<int> set = Set();
  dynamic dyn = map;
  Iterable<int> iterable = [];
  CustomSet customSet = CustomSet();
  CustomMap customMap = CustomMap();

  var _ = {...dyn}; //# 00: compile-time error
  var _ = {...map, ...set}; //# 01: compile-time error
  var _ = {...map, ...iterable}; //# 02: compile-time error
  var _ = {...map, ...customSet}; //# 03: compile-time error
  var _ = {...set, ...customMap}; //# 04: compile-time error
  var _ = {...dyn, ...dyn}; //# 05: compile-time error
  var _ = {...iterable, ...customMap}; //# 06: compile-time error
  var _ = {...customSet, ...customMap}; //# 07: compile-time error
}
