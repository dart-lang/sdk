// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

import 'utils.dart';

final nonConstBool = true;
final nonConstInt = 3;

const dynamic nonBool = 3;
const dynamic nonInt = "s";

void main() {
  testList();
  testMap();
  testSet();
  testShortCircuit();
}

void testList() {
  // Condition must be constant.
  const _ = <int>[if (nonConstBool) 1]; //# 01: compile-time error

  // Condition must be Boolean.
  const _ = <int>[if (nonBool) 1]; //# 02: compile-time error

  // Then element must be constant, whether or not branch is taken.
  const _ = <int>[if (true) nonConstInt]; //# 03: compile-time error
  const _ = <int>[if (false) nonConstInt]; //# 04: compile-time error

  // Else element must be constant, whether or not branch is taken.
  const _ = <int>[if (true) 1 else nonConstInt]; //# 05: compile-time error
  const _ = <int>[if (false) 1 else nonConstInt]; //# 06: compile-time error

  // Then element must have right type if branch is chosen.
  const _ = <int>[if (true) nonInt]; //# 07: compile-time error

  // Else element must have right type if branch is chosen.
  const _ = <int>[if (false) 9 else nonInt]; //# 08: compile-time error
}

void testMap() {
  // Condition must be constant.
  const _ = <int, int>{if (nonConstBool) 1: 1}; //# 09: compile-time error

  // Condition must be Boolean.
  const _ = <int, int>{if (nonBool) 1: 1}; //# 10: compile-time error

  // Then key element must be constant, whether or not branch is taken.
  const _ = <int, int>{if (true) nonConstInt: 1}; //# 11: compile-time error
  const _ = <int, int>{if (false) nonConstInt: 1}; //# 12: compile-time error

  // Then value element must be constant, whether or not branch is taken.
  const _ = <int, int>{if (true) 1: nonConstInt}; //# 13: compile-time error
  const _ = <int, int>{if (false) 1: nonConstInt}; //# 14: compile-time error

  // Else key element must be constant, whether or not branch is taken.
  const _ = <int, int>{if (true) 1 else nonConstInt: 1}; //# 15: compile-time error
  const _ = <int, int>{if (false) 1 else nonConstInt: 1}; //# 16: compile-time error

  // Else value element must be constant, whether or not branch is taken.
  const _ = <int, int>{if (true) 1 else 1: nonConstInt}; //# 17: compile-time error
  const _ = <int, int>{if (false) 1 else 1: nonConstInt}; //# 18: compile-time error

  // Then key element must have right type if branch is chosen.
  const _ = <int, int>{if (true) nonInt: 1}; //# 19: compile-time error

  // Then value element must have right type if branch is chosen.
  const _ = <int, int>{if (true) 1: nonInt}; //# 20: compile-time error

  // Else key element must have right type if branch is chosen.
  const _ = <int, int>{if (false) 9 else nonInt: 1}; //# 21: compile-time error

  // Else value element must have right type if branch is chosen.
  const _ = <int, int>{if (false) 9 else 1: nonInt}; //# 22: compile-time error

  // Key cannot override operator.==().
  const obj = 0.1;
  const _ = {if (true) 0.1: 1}; //# 23: compile-time error
  const _ = {if (true) Duration(seconds: 0): 1}; //# 24: compile-time error
  const _ = {if (true) obj: 1}; //# 25: compile-time error

  // Cannot have key collision when branch is chosen.
  const _ = <int, int>{1: 1, if (true) 1: 1}; //# 25: compile-time error
  const _ = <int, int>{if (true) 1: 1, if (true) 1: 1}; //# 26: compile-time error
}

void testSet() {
  // Condition must be constant.
  const _ = <int>{if (nonConstBool) 1}; //# 27: compile-time error

  // Condition must be Boolean.
  const _ = <int>{if (nonBool) 1}; //# 28: compile-time error

  // Then element must be constant, whether or not branch is taken.
  const _ = <int>{if (true) nonConstInt}; //# 29: compile-time error
  const _ = <int>{if (false) nonConstInt}; //# 30: compile-time error

  // Else element must be constant, whether or not branch is taken.
  const _ = <int>{if (true) 1 else nonConstInt}; //# 31: compile-time error
  const _ = <int>{if (false) 1 else nonConstInt}; //# 32: compile-time error

  // Then element must have right type if branch is chosen.
  const _ = <int>{if (true) nonInt}; //# 33: compile-time error

  // Else element must have right type if branch is chosen.
  const _ = <int>{if (false) 9 else nonInt}; //# 34: compile-time error

  // Cannot override operator.==().
  const obj = 0.1;
  const _ = {if (true) 0.1}; //# 35: compile-time error
  const _ = {if (true) Duration(seconds: 0)}; //# 36: compile-time error
  const _ = {if (true) obj}; //# 37: compile-time error

  // Cannot have collision when branch is chosen.
  const _ = <int>{1, if (true) 1}; //# 38: compile-time error
  const _ = <int>{if (true) 1, if (true) 1}; //# 39: compile-time error
}

void testShortCircuit() {
  // A const expression that throws causes a compile error if it occurs inside
  // the chosen branch of an if.

  // Store null in a dynamically-typed constant to avoid the type error on "+".
  const dynamic nil = null;

  // With no else.
  const _ = [if (true) nil + 1]; //# 40: compile-time error

  // With else.
  const _ = [if (true) nil + 1 else 1]; //# 41: compile-time error
  const _ = [if (false) 1 else nil + 1]; //# 42: compile-time error
}
