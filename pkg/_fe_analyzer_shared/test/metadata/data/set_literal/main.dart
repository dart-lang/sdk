// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const List<int> constList = [];

const List<int>? constNullableList = [];

@Helper({0})
/*member: setLiterals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))}))))
resolved=SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))})*/
void setLiterals1() {}

@Helper({0, 1})
/*member: setLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))})*/
void setLiterals2() {}

@Helper({0, 1, 2})
/*member: setLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))})*/
void setLiterals3() {}

@Helper(<int>{})
/*member: setLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{}))))
resolved=SetOrMapLiteral(<int>{})*/
void setLiterals4() {}

@Helper(<int>{0})
/*member: setLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{ExpressionElement(IntegerLiteral(0))}))))
resolved=SetOrMapLiteral(<int>{ExpressionElement(IntegerLiteral(0))})*/
void setLiterals5() {}

@Helper(<int>{0, 1})
/*member: setLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))})*/
void setLiterals6() {}

@Helper(<int>{0, 1, 2})
/*member: setLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))})*/
void setLiterals7() {}

@Helper(<int>{0, 1, ...[]})
/*member: setLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(...ListLiteral([]))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...ListLiteral([]))})*/
void setLiterals8() {}

@Helper(<int>{0, 1, ...constList})
/*member: setLiterals9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...StaticGet(constList))})*/
void setLiterals9() {}

@Helper(<int>{0, 1, ...?constNullableList})
/*member: setLiterals10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(?...StaticGet(constNullableList))})*/
void setLiterals10() {}

@Helper(<int>{0, 1, if (constBool) 2})
/*member: setLiterals11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    StaticGet(constBool),
    ExpressionElement(IntegerLiteral(2)))})*/
void setLiterals11() {}

@Helper(<int>{0, 1, if (constBool) 2 else 3})
/*member: setLiterals12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)),
      ExpressionElement(IntegerLiteral(3)))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    StaticGet(constBool),
    ExpressionElement(IntegerLiteral(2)),
    ExpressionElement(IntegerLiteral(3)))})*/
void setLiterals12() {}

@Helper(const {0})
/*member: setLiterals13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))}))))
resolved=SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))})*/
void setLiterals13() {}

@Helper(const {0, 1})
/*member: setLiterals14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))})*/
void setLiterals14() {}

@Helper(const {0, 1, 2})
/*member: setLiterals15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))}))))
resolved=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))})*/
void setLiterals15() {}

@Helper(const <int>{})
/*member: setLiterals16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{}))))
resolved=SetOrMapLiteral(<int>{})*/
void setLiterals16() {}

@Helper(const <int>{0})
/*member: setLiterals17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{ExpressionElement(IntegerLiteral(0))}))))
resolved=SetOrMapLiteral(<int>{ExpressionElement(IntegerLiteral(0))})*/
void setLiterals17() {}

@Helper(const <int>{0, 1})
/*member: setLiterals18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))})*/
void setLiterals18() {}

@Helper(const <int>{0, 1, 2})
/*member: setLiterals19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))}))))
resolved=SetOrMapLiteral(<int>{
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))})*/
void setLiterals19() {}
