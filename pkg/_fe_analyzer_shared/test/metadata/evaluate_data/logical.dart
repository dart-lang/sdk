// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

@Helper(true && true)
/*member: logicalExpression1:
resolved=LogicalExpression(BooleanLiteral(true) && BooleanLiteral(true))
evaluate=BooleanLiteral(true)*/
void logicalExpression1() {}

@Helper(true && false)
/*member: logicalExpression2:
resolved=LogicalExpression(BooleanLiteral(true) && BooleanLiteral(false))
evaluate=BooleanLiteral(false)*/
void logicalExpression2() {}

@Helper(false && true)
/*member: logicalExpression3:
resolved=LogicalExpression(BooleanLiteral(false) && BooleanLiteral(true))
evaluate=BooleanLiteral(false)*/
void logicalExpression3() {}

@Helper(false && false)
/*member: logicalExpression4:
resolved=LogicalExpression(BooleanLiteral(false) && BooleanLiteral(false))
evaluate=BooleanLiteral(false)*/
void logicalExpression4() {}

@Helper(true || true)
/*member: logicalExpression5:
resolved=LogicalExpression(BooleanLiteral(true) || BooleanLiteral(true))
evaluate=BooleanLiteral(true)*/
void logicalExpression5() {}

@Helper(true || false)
/*member: logicalExpression6:
resolved=LogicalExpression(BooleanLiteral(true) || BooleanLiteral(false))
evaluate=BooleanLiteral(true)*/
void logicalExpression6() {}

@Helper(false || true)
/*member: logicalExpression7:
resolved=LogicalExpression(BooleanLiteral(false) || BooleanLiteral(true))
evaluate=BooleanLiteral(true)*/
void logicalExpression7() {}

@Helper(false || false)
/*member: logicalExpression8:
resolved=LogicalExpression(BooleanLiteral(false) || BooleanLiteral(false))
evaluate=BooleanLiteral(false)*/
void logicalExpression8() {}

@Helper(constBool && true)
/*member: logicalExpression9:
resolved=LogicalExpression(StaticGet(constBool) && BooleanLiteral(true))
evaluate=BooleanLiteral(true)
constBool=BooleanLiteral(true)*/
void logicalExpression9() {}

@Helper(constBool && false)
/*member: logicalExpression10:
resolved=LogicalExpression(StaticGet(constBool) && BooleanLiteral(false))
evaluate=BooleanLiteral(false)
constBool=BooleanLiteral(true)*/
void logicalExpression10() {}

@Helper(constBool || true)
/*member: logicalExpression11:
resolved=LogicalExpression(StaticGet(constBool) || BooleanLiteral(true))
evaluate=BooleanLiteral(true)
constBool=BooleanLiteral(true)*/
void logicalExpression11() {}

@Helper(constBool || false)
/*member: logicalExpression12:
resolved=LogicalExpression(StaticGet(constBool) || BooleanLiteral(false))
evaluate=BooleanLiteral(true)
constBool=BooleanLiteral(true)*/
void logicalExpression12() {}
