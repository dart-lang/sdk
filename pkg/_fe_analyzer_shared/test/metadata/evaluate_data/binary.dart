// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const int constInt = 42;

@Helper(1 < 2)
/*member: binary1:
resolved=BinaryExpression(IntegerLiteral(1) < IntegerLiteral(2))
evaluate=BooleanLiteral(true)*/
void binary1() {}

@Helper(1 <= 2)
/*member: binary2:
resolved=BinaryExpression(IntegerLiteral(1) <= IntegerLiteral(2))
evaluate=BooleanLiteral(true)*/
void binary2() {}

@Helper(1 > 2)
/*member: binary3:
resolved=BinaryExpression(IntegerLiteral(1) > IntegerLiteral(2))
evaluate=BooleanLiteral(false)*/
void binary3() {}

@Helper(1 >= 2)
/*member: binary4:
resolved=BinaryExpression(IntegerLiteral(1) >= IntegerLiteral(2))
evaluate=BooleanLiteral(false)*/
void binary4() {}

@Helper(1 | 2)
/*member: binary5:
resolved=BinaryExpression(IntegerLiteral(1) | IntegerLiteral(2))
evaluate=IntegerLiteral(value=3)*/
void binary5() {}

@Helper(1 ^ 2)
/*member: binary6:
resolved=BinaryExpression(IntegerLiteral(1) ^ IntegerLiteral(2))
evaluate=IntegerLiteral(value=3)*/
void binary6() {}

@Helper(1 & 2)
/*member: binary7:
resolved=BinaryExpression(IntegerLiteral(1) & IntegerLiteral(2))
evaluate=IntegerLiteral(value=0)*/
void binary7() {}

@Helper(1 >> 2)
/*member: binary8:
resolved=BinaryExpression(IntegerLiteral(1) >> IntegerLiteral(2))
evaluate=IntegerLiteral(value=0)*/
void binary8() {}

@Helper(1 >>> 2)
/*member: binary9:
resolved=BinaryExpression(IntegerLiteral(1) >>> IntegerLiteral(2))
evaluate=IntegerLiteral(value=0)*/
void binary9() {}

@Helper(1 << 2)
/*member: binary10:
resolved=BinaryExpression(IntegerLiteral(1) << IntegerLiteral(2))
evaluate=IntegerLiteral(value=4)*/
void binary10() {}

@Helper(1 + 2)
/*member: binary11:
resolved=BinaryExpression(IntegerLiteral(1) + IntegerLiteral(2))
evaluate=IntegerLiteral(value=3)*/
void binary11() {}

@Helper(1 - 2)
/*member: binary12:
resolved=BinaryExpression(IntegerLiteral(1) - IntegerLiteral(2))
evaluate=IntegerLiteral(value=-1)*/
void binary12() {}

@Helper(1 * 2)
/*member: binary13:
resolved=BinaryExpression(IntegerLiteral(1) * IntegerLiteral(2))
evaluate=IntegerLiteral(value=2)*/
void binary13() {}

@Helper(1 / 2)
/*member: binary14:
resolved=BinaryExpression(IntegerLiteral(1) / IntegerLiteral(2))
evaluate=DoubleLiteral(0.5)*/
void binary14() {}

@Helper(1 / 0)
/*member: binary15:
resolved=BinaryExpression(IntegerLiteral(1) / IntegerLiteral(0))
evaluate=BinaryExpression(IntegerLiteral(1) / IntegerLiteral(0))*/
void binary15() {}

@Helper(1 ~/ 2)
/*member: binary16:
resolved=BinaryExpression(IntegerLiteral(1) ~/ IntegerLiteral(2))
evaluate=IntegerLiteral(value=0)*/
void binary16() {}

@Helper(1 ~/ 0)
/*member: binary17:
resolved=BinaryExpression(IntegerLiteral(1) ~/ IntegerLiteral(0))
evaluate=BinaryExpression(IntegerLiteral(1) ~/ IntegerLiteral(0))*/
void binary17() {}

@Helper(1 % 2)
/*member: binary18:
resolved=BinaryExpression(IntegerLiteral(1) % IntegerLiteral(2))
evaluate=IntegerLiteral(value=1)*/
void binary18() {}

@Helper(1 / 0)
/*member: binary19:
resolved=BinaryExpression(IntegerLiteral(1) / IntegerLiteral(0))
evaluate=BinaryExpression(IntegerLiteral(1) / IntegerLiteral(0))*/
void binary19() {}

@Helper(1 + constInt)
/*member: binary20:
resolved=BinaryExpression(IntegerLiteral(1) + StaticGet(constInt))
evaluate=IntegerLiteral(value=43)
constInt=IntegerLiteral(42)*/
void binary20() {}
