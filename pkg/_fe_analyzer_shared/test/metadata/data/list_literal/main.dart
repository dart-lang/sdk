// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const List<int> constList = [];

const List<int>? constNullableList = [];

@Helper([])
/*member: listLiterals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([]))))
resolved=ListLiteral([])*/
void listLiterals1() {}

@Helper([0])
/*member: listLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([ExpressionElement(IntegerLiteral(0))]))))
resolved=ListLiteral([ExpressionElement(IntegerLiteral(0))])*/
void listLiterals2() {}

@Helper([0, 1])
/*member: listLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))])*/
void listLiterals3() {}

@Helper([0, 1, 2])
/*member: listLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))])*/
void listLiterals4() {}

@Helper(<int>[])
/*member: listLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[]))))
resolved=ListLiteral(<int>[])*/
void listLiterals5() {}

@Helper(<int>[0])
/*member: listLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[ExpressionElement(IntegerLiteral(0))]))))
resolved=ListLiteral(<int>[ExpressionElement(IntegerLiteral(0))])*/
void listLiterals6() {}

@Helper(<int>[0, 1])
/*member: listLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))])*/
void listLiterals7() {}

@Helper(<int>[0, 1, 2])
/*member: listLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))])*/
void listLiterals8() {}

@Helper(<int>[0, 1, ...[]])
/*member: listLiterals9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(...ListLiteral([]))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...ListLiteral([]))])*/
void listLiterals9() {}

@Helper(<int>[0, 1, ...constList])
/*member: listLiterals10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(...UnresolvedExpression(UnresolvedIdentifier(constList)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(...StaticGet(constList))])*/
void listLiterals10() {}

@Helper(<int>[0, 1, ...?constNullableList])
/*member: listLiterals11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableList)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  SpreadElement(?...StaticGet(constNullableList))])*/
void listLiterals11() {}

@Helper(<int>[0, 1, if (constBool) 2])
/*member: listLiterals12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    StaticGet(constBool),
    ExpressionElement(IntegerLiteral(2)))])*/
void listLiterals12() {}

@Helper(<int>[0, 1, if (constBool) 2 else 3])
/*member: listLiterals13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      ExpressionElement(IntegerLiteral(2)),
      ExpressionElement(IntegerLiteral(3)))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  IfElement(
    StaticGet(constBool),
    ExpressionElement(IntegerLiteral(2)),
    ExpressionElement(IntegerLiteral(3)))])*/
void listLiterals13() {}

@Helper(const [])
/*member: listLiterals14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([]))))
resolved=ListLiteral([])*/
void listLiterals14() {}

@Helper(const [0])
/*member: listLiterals15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([ExpressionElement(IntegerLiteral(0))]))))
resolved=ListLiteral([ExpressionElement(IntegerLiteral(0))])*/
void listLiterals15() {}

@Helper(const [0, 1])
/*member: listLiterals16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))])*/
void listLiterals16() {}

@Helper(const [0, 1, 2])
/*member: listLiterals17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral([
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))]))))
resolved=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))])*/
void listLiterals17() {}

@Helper(const <int>[])
/*member: listLiterals18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[]))))
resolved=ListLiteral(<int>[])*/
void listLiterals18() {}

@Helper(const <int>[0])
/*member: listLiterals19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[ExpressionElement(IntegerLiteral(0))]))))
resolved=ListLiteral(<int>[ExpressionElement(IntegerLiteral(0))])*/
void listLiterals19() {}

@Helper(const <int>[0, 1])
/*member: listLiterals20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))])*/
void listLiterals20() {}

@Helper(const <int>[0, 1, 2])
/*member: listLiterals21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (ListLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)}>[
    ExpressionElement(IntegerLiteral(0)), 
    ExpressionElement(IntegerLiteral(1)), 
    ExpressionElement(IntegerLiteral(2))]))))
resolved=ListLiteral(<int>[
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1)), 
  ExpressionElement(IntegerLiteral(2))])*/
void listLiterals21() {}
