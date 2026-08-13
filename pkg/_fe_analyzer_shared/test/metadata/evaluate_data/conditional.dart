// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

@Helper(true ? 0 : 1)
/*member: conditional1:
resolved=ConditionalExpression(
  BooleanLiteral(true)
    ? IntegerLiteral(0)
    : IntegerLiteral(1))
evaluate=IntegerLiteral(0)*/
void conditional1() {}

@Helper(false ? 0 : 1)
/*member: conditional2:
resolved=ConditionalExpression(
  BooleanLiteral(false)
    ? IntegerLiteral(0)
    : IntegerLiteral(1))
evaluate=IntegerLiteral(1)*/
void conditional2() {}
