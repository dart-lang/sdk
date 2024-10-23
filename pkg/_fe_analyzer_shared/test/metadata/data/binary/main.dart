// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const List<int>? constNullableList = [];

@Helper(constNullableList ?? [0])
/*member: binary1:
IfNull(
  StaticGet(constNullableList)
   ?? 
  ListLiteral([ExpressionElement(IntegerLiteral(0))])
)*/
void binary1() {}

@Helper(constBool || true)
/*member: binary2:
LogicalExpression(StaticGet(constBool) || BooleanLiteral(true))*/
void binary2() {}

@Helper(constBool && true)
/*member: binary3:
LogicalExpression(StaticGet(constBool) && BooleanLiteral(true))*/
void binary3() {}

@Helper(0 == 1)
/*member: binary4:
EqualityExpression(IntegerLiteral(0) == IntegerLiteral(1))*/
void binary4() {}

@Helper(0 != 1)
/*member: binary5:
EqualityExpression(IntegerLiteral(0) != IntegerLiteral(1))*/
void binary5() {}

@Helper(0 >= 1)
/*member: binary6:
BinaryExpression(IntegerLiteral(0) >= IntegerLiteral(1))*/
void binary6() {}

@Helper(0 > 1)
/*member: binary7:
BinaryExpression(IntegerLiteral(0) > IntegerLiteral(1))*/
void binary7() {}

@Helper(0 <= 1)
/*member: binary8:
BinaryExpression(IntegerLiteral(0) <= IntegerLiteral(1))*/
void binary8() {}

@Helper(0 < 1)
/*member: binary9:
BinaryExpression(IntegerLiteral(0) < IntegerLiteral(1))*/
void binary9() {}

@Helper(0 | 1)
/*member: binary10:
BinaryExpression(IntegerLiteral(0) | IntegerLiteral(1))*/
void binary10() {}

@Helper(0 & 1)
/*member: binary11:
BinaryExpression(IntegerLiteral(0) & IntegerLiteral(1))*/
void binary11() {}

@Helper(0 ^ 1)
/*member: binary12:
BinaryExpression(IntegerLiteral(0) ^ IntegerLiteral(1))*/
void binary12() {}

@Helper(0 << 1)
/*member: binary13:
BinaryExpression(IntegerLiteral(0) << IntegerLiteral(1))*/
void binary13() {}

@Helper(0 >> 1)
/*member: binary14:
BinaryExpression(IntegerLiteral(0) >> IntegerLiteral(1))*/
void binary14() {}

@Helper(0 >>> 1)
/*member: binary15:
BinaryExpression(IntegerLiteral(0) >>> IntegerLiteral(1))*/
void binary15() {}

@Helper(0 + 1)
/*member: binary16:
BinaryExpression(IntegerLiteral(0) + IntegerLiteral(1))*/
void binary16() {}

@Helper(0 - 1)
/*member: binary17:
BinaryExpression(IntegerLiteral(0) - IntegerLiteral(1))*/
void binary17() {}

@Helper(0 * 1)
/*member: binary18:
BinaryExpression(IntegerLiteral(0) * IntegerLiteral(1))*/
void binary18() {}

@Helper(0 / 1)
/*member: binary19:
BinaryExpression(IntegerLiteral(0) / IntegerLiteral(1))*/
void binary19() {}

@Helper(0 % 1)
/*member: binary20:
BinaryExpression(IntegerLiteral(0) % IntegerLiteral(1))*/
void binary20() {}

@Helper(0 ~/ 1)
/*member: binary21:
BinaryExpression(IntegerLiteral(0) ~/ IntegerLiteral(1))*/
void binary21() {}
