// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const int constInt = 42;

@Helper(null == null)
/*member: equalityExpression1:
resolved=EqualityExpression(NullLiteral() == NullLiteral())
evaluate=BooleanLiteral(true)*/
void equalityExpression1() {}

@Helper(null != null)
/*member: equalityExpression2:
resolved=EqualityExpression(NullLiteral() != NullLiteral())
evaluate=BooleanLiteral(false)*/
void equalityExpression2() {}

@Helper(0 == 0)
/*member: equalityExpression3:
resolved=EqualityExpression(IntegerLiteral(0) == IntegerLiteral(0))
evaluate=BooleanLiteral(true)*/
void equalityExpression3() {}

@Helper(0 != 0)
/*member: equalityExpression4:
resolved=EqualityExpression(IntegerLiteral(0) != IntegerLiteral(0))
evaluate=BooleanLiteral(false)*/
void equalityExpression4() {}

@Helper(0 == 1)
/*member: equalityExpression5:
resolved=EqualityExpression(IntegerLiteral(0) == IntegerLiteral(1))
evaluate=BooleanLiteral(false)*/
void equalityExpression5() {}

@Helper(0 != 1)
/*member: equalityExpression6:
resolved=EqualityExpression(IntegerLiteral(0) != IntegerLiteral(1))
evaluate=BooleanLiteral(true)*/
void equalityExpression6() {}

@Helper(constInt == 1)
/*member: equalityExpression7:
resolved=EqualityExpression(StaticGet(constInt) == IntegerLiteral(1))
evaluate=BooleanLiteral(false)
constInt=IntegerLiteral(42)*/
void equalityExpression7() {}

@Helper(constInt != 1)
/*member: equalityExpression8:
resolved=EqualityExpression(StaticGet(constInt) != IntegerLiteral(1))
evaluate=BooleanLiteral(true)
constInt=IntegerLiteral(42)*/
void equalityExpression8() {}
