// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[testSwitchWithFallthrough(1)],
 type=[inst:JSNull]
*/
main() {
  testSwitchWithFallthrough(null);
}

/*element: testSwitchWithFallthrough:
 static=[
  FallThroughError._create(2),
  throwExpression,
  wrapException],
 type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSString,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testSwitchWithFallthrough(o) {
  switch (o) {
    case 0:
    // ignore: CASE_BLOCK_NOT_TERMINATED
    case 1:
      o = 2;
    case 2:
      o = 3;
      return;
    case 3:
    default:
  }
}
