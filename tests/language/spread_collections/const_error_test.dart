// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'helper_classes.dart';

var nonConstList = <int>[];
var nonConstMap = <int, String>{};
var nonConstSet = <int>{};
const dynamic nonIterable = 3;
const dynamic nonMap = 3;

void main() {
  testList();
  testMap();
  testSet();
}

void testList() {
  // Must be constant.
  const _ = <int>[...nonConstList]; //# 01: compile-time error

  // Must be iterable.
  const _ = <int>[...nonIterable]; //# 02: compile-time error

  // Cannot be custom iterable type.
  const _ = <int>[...ConstIterable()]; //# 03: compile-time error
}

void testMap() {
  // Must be constant.
  const _ = <int, String>{...nonConstMap}; //# 04: compile-time error

  // Must be map.
  const _ = <int, String>{...nonMap}; //# 05: compile-time error

  // Cannot be custom map type.
  const _ = <int, String>{...ConstMap()}; //# 06: compile-time error

  // Cannot have key collision.
  const _ = <int, String>{1: "s", ...{1: "t"}}; //# 07: compile-time error
  const _ = <int, String>{...{1: "s"}, ...{1: "t"}}; //# 08: compile-time error
}

void testSet() {
  // Must be constant.
  const _ = <int>{...nonConstList}; //# 09: compile-time error
  const _ = <int>{...nonConstSet}; //# 10: compile-time error

  // Must be iterable.
  const _ = <int>{...nonIterable}; //# 11: compile-time error

  // Cannot be custom iterable type.
  const _ = <int>{...ConstIterable()}; //# 12: compile-time error

  // Cannot override operator.==().
  const obj = 0.1;
  const _ = {...[0.1]}; //# 13: compile-time error
  const _ = {...[Duration(seconds: 0)]}; //# 14: compile-time error
  const _ = {...[obj]}; //# 15: compile-time error

  // Cannot have collision.
  const _ = {1, ...[1]}; //# 16: compile-time error
  const _ = {...[1, 1, 3, 8]}; //# 17: compile-time error
  const _ = {...[1], ...[1]}; //# 18: compile-time error
}
