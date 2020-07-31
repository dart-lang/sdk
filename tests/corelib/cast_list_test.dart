// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";
import 'cast_helper.dart';

void main() {
  testDowncast();
  testUpcast();
  testRegression();
}

void testDowncast() {
  var list = new List<C?>.from(elements);
  var dList = List.castFrom<C?, D?>(list);

  Expect.throws(() => dList.first); // C is not D?.
  Expect.equals(d, dList[1]);
  Expect.throws(() => dList[2]); // E is not D?.
  Expect.equals(f, dList[3]);
  Expect.equals(null, dList.last);

  Expect.throws(() => dList.toList());

  // Setting works.
  dList[2] = d;
  Expect.equals(d, dList[2]);
}

void testUpcast() {
  var list = new List<C?>.from(elements);
  var objectList = List.castFrom<C?, Object?>(list);
  Expect.listEquals(elements, objectList);
  Expect.throws(() => objectList[2] = new Object()); // Cannot set non-C.
  Expect.listEquals(elements, objectList);
}

void testRegression() {
  var numList = <num>[4, 3, 2, 1];
  var intList = numList.cast<int>();
  intList.sort(null);
  Expect.listEquals([1, 2, 3, 4], numList);
  Expect.listEquals([1, 2, 3, 4], intList);
}
