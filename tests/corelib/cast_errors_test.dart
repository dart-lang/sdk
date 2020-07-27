// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import 'cast_helper.dart';

void main() {
  testSetDowncast();
  testMapDowncast();
}

void testSetDowncast() {
  var setEls = new Set<C?>.from(elements);
  var dSet = Set.castFrom<C?, D?>(setEls);

  var newC = new C();
  dSet.add(newC);
  //       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'C' can't be assigned to the parameter type 'D?'.
}

void testMapDowncast() {
  var map = new Map.fromIterables(elements, elements);
  var dMap = Map.castFrom<C?, C?, D?, D?>(map);

  dMap[c] = d;
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'D?'.
  dMap[d] = c;
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'D?'.
}
