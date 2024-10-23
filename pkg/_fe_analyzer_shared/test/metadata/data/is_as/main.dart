// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper(0 is int)
/*member: isAs1:
IsTest(IntegerLiteral(0) is int)*/
void isAs1() {}

@Helper(0 is! String)
/*member: isAs2:
IsTest(IntegerLiteral(0) is! String)*/
void isAs2() {}

@Helper(0 as int)
/*member: isAs3:
AsExpression(IntegerLiteral(0) as int)*/
void isAs3() {}
