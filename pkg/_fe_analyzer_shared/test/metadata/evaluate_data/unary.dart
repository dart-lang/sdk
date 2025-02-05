// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const int constInt = 42;

@Helper(!false)
/*member: unary1:
resolved=UnaryExpression(!BooleanLiteral(false))
evaluate=BooleanLiteral(true)*/
void unary1() {}

@Helper(!true)
/*member: unary2:
resolved=UnaryExpression(!BooleanLiteral(true))
evaluate=BooleanLiteral(false)*/
void unary2() {}

@Helper(-1)
/*member: unary3:
resolved=UnaryExpression(-IntegerLiteral(1))
evaluate=IntegerLiteral(value=-1)*/
void unary3() {}

@Helper(~2)
/*member: unary4:
resolved=UnaryExpression(~IntegerLiteral(2))
evaluate=IntegerLiteral(value=-3)*/
void unary4() {}

@Helper(!constBool)
/*member: unary5:
resolved=UnaryExpression(!StaticGet(constBool))
evaluate=BooleanLiteral(false)
constBool=BooleanLiteral(true)*/
void unary5() {}

@Helper(-constInt)
/*member: unary6:
resolved=UnaryExpression(-StaticGet(constInt))
evaluate=IntegerLiteral(value=-42)
constInt=IntegerLiteral(42)*/
void unary6() {}
