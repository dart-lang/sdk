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
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (IfNull(
    UnresolvedExpression(UnresolvedIdentifier(constNullableList))
     ?? 
    ListLiteral([ExpressionElement(IntegerLiteral(0))])
  ))))
resolved=IfNull(
  StaticGet(constNullableList)
   ?? 
  ListLiteral([ExpressionElement(IntegerLiteral(0))])
)*/
void binary1() {}

@Helper(constBool || true)
/*member: binary2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) || BooleanLiteral(true)))))
resolved=LogicalExpression(StaticGet(constBool) || BooleanLiteral(true))*/
void binary2() {}

@Helper(constBool && true)
/*member: binary3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (LogicalExpression(UnresolvedExpression(UnresolvedIdentifier(constBool)) && BooleanLiteral(true)))))
resolved=LogicalExpression(StaticGet(constBool) && BooleanLiteral(true))*/
void binary3() {}

@Helper(0 == 1)
/*member: binary4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (EqualityExpression(IntegerLiteral(0) == IntegerLiteral(1)))))
resolved=EqualityExpression(IntegerLiteral(0) == IntegerLiteral(1))*/
void binary4() {}

@Helper(0 != 1)
/*member: binary5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (EqualityExpression(IntegerLiteral(0) != IntegerLiteral(1)))))
resolved=EqualityExpression(IntegerLiteral(0) != IntegerLiteral(1))*/
void binary5() {}

@Helper(0 >= 1)
/*member: binary6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) >= IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) >= IntegerLiteral(1))*/
void binary6() {}

@Helper(0 > 1)
/*member: binary7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) > IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) > IntegerLiteral(1))*/
void binary7() {}

@Helper(0 <= 1)
/*member: binary8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) <= IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) <= IntegerLiteral(1))*/
void binary8() {}

@Helper(0 < 1)
/*member: binary9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) < IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) < IntegerLiteral(1))*/
void binary9() {}

@Helper(0 | 1)
/*member: binary10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) | IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) | IntegerLiteral(1))*/
void binary10() {}

@Helper(0 & 1)
/*member: binary11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) & IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) & IntegerLiteral(1))*/
void binary11() {}

@Helper(0 ^ 1)
/*member: binary12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) ^ IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) ^ IntegerLiteral(1))*/
void binary12() {}

@Helper(0 << 1)
/*member: binary13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) << IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) << IntegerLiteral(1))*/
void binary13() {}

@Helper(0 >> 1)
/*member: binary14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) >> IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) >> IntegerLiteral(1))*/
void binary14() {}

@Helper(0 >>> 1)
/*member: binary15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) >>> IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) >>> IntegerLiteral(1))*/
void binary15() {}

@Helper(0 + 1)
/*member: binary16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) + IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) + IntegerLiteral(1))*/
void binary16() {}

@Helper(0 - 1)
/*member: binary17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) - IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) - IntegerLiteral(1))*/
void binary17() {}

@Helper(0 * 1)
/*member: binary18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) * IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) * IntegerLiteral(1))*/
void binary18() {}

@Helper(0 / 1)
/*member: binary19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) / IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) / IntegerLiteral(1))*/
void binary19() {}

@Helper(0 % 1)
/*member: binary20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) % IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) % IntegerLiteral(1))*/
void binary20() {}

@Helper(0 ~/ 1)
/*member: binary21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (BinaryExpression(IntegerLiteral(0) ~/ IntegerLiteral(1)))))
resolved=BinaryExpression(IntegerLiteral(0) ~/ IntegerLiteral(1))*/
void binary21() {}
