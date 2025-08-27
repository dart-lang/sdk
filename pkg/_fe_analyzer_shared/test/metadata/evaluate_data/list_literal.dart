// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const int constInt = 42;

const List<int> constList = [2, 3];

@Helper([0])
/*member: listLiteral1:
resolved=ListLiteral([ExpressionElement(IntegerLiteral(0))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(0))])*/
void listLiteral1() {}

@Helper([?0])
/*member: listLiteral2:
resolved=ListLiteral([ExpressionElement(?IntegerLiteral(0))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(0))])*/
void listLiteral2() {}

@Helper([?null])
/*member: listLiteral3:
resolved=ListLiteral([ExpressionElement(?NullLiteral())])
evaluate=ListLiteral([])*/
void listLiteral3() {}

@Helper([?constInt])
/*member: listLiteral4:
resolved=ListLiteral([ExpressionElement(?StaticGet(constInt))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(42))])
constInt=IntegerLiteral(42)*/
void listLiteral4() {}

@Helper([if (true) 1])
/*member: listLiteral5:
resolved=ListLiteral([IfElement(
  BooleanLiteral(true),
  ExpressionElement(IntegerLiteral(1)))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(1))])*/
void listLiteral5() {}

@Helper([if (false) 1])
/*member: listLiteral6:
resolved=ListLiteral([IfElement(
  BooleanLiteral(false),
  ExpressionElement(IntegerLiteral(1)))])
evaluate=ListLiteral([])*/
void listLiteral6() {}

@Helper([if (constBool) 1])
/*member: listLiteral7:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  ExpressionElement(IntegerLiteral(1)))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(1))])
constBool=BooleanLiteral(true)*/
void listLiteral7() {}

@Helper([if (true) 1 else 2])
/*member: listLiteral8:
resolved=ListLiteral([IfElement(
  BooleanLiteral(true),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(IntegerLiteral(2)))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(1))])*/
void listLiteral8() {}

@Helper([if (false) 1 else 2])
/*member: listLiteral9:
resolved=ListLiteral([IfElement(
  BooleanLiteral(false),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(IntegerLiteral(2)))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(2))])*/
void listLiteral9() {}

@Helper([if (constBool) 1 else 2])
/*member: listLiteral10:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(IntegerLiteral(2)))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(1))])
constBool=BooleanLiteral(true)*/
void listLiteral10() {}

@Helper([
  ...[0, 1],
])
/*member: listLiteral11:
resolved=ListLiteral([SpreadElement(...ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))]))])
evaluate=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))])*/
void listLiteral11() {}

@Helper([...constList])
/*member: listLiteral12:
resolved=ListLiteral([SpreadElement(...StaticGet(constList))])
evaluate=ListLiteral([
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))])
constList=ListLiteral([
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))])*/
void listLiteral12() {}

@Helper([
  ...?[0, 1],
])
/*member: listLiteral13:
resolved=ListLiteral([SpreadElement(?...ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))]))])
evaluate=ListLiteral([
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))])*/
void listLiteral13() {}

@Helper([...?constList])
/*member: listLiteral14:
resolved=ListLiteral([SpreadElement(?...StaticGet(constList))])
evaluate=ListLiteral([
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))])
constList=ListLiteral([
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))])*/
void listLiteral14() {}

@Helper([...?null])
/*member: listLiteral15:
resolved=ListLiteral([SpreadElement(?...NullLiteral())])
evaluate=ListLiteral([])*/
void listLiteral15() {}

@Helper([if (constBool) ?null])
/*member: listLiteral16:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  ExpressionElement(?NullLiteral()))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral16() {}

@Helper([if (constBool) ?null else 2])
/*member: listLiteral17:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  ExpressionElement(?NullLiteral()),
  ExpressionElement(IntegerLiteral(2)))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral17() {}

@Helper([if (constBool) 1 else ?null])
/*member: listLiteral18:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(?NullLiteral()))])
evaluate=ListLiteral([ExpressionElement(IntegerLiteral(1))])
constBool=BooleanLiteral(true)*/
void listLiteral18() {}

@Helper([if (constBool) ?null else ?null])
/*member: listLiteral19:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  ExpressionElement(?NullLiteral()),
  ExpressionElement(?NullLiteral()))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral19() {}

@Helper([if (constBool) ...[]])
/*member: listLiteral20:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  SpreadElement(...ListLiteral([])))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral20() {}

@Helper([if (constBool) ...{}])
/*member: listLiteral21:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  SpreadElement(...SetOrMapLiteral({})))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral21() {}

@Helper([if (constBool) ...?[]])
/*member: listLiteral22:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  SpreadElement(?...ListLiteral([])))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral22() {}

@Helper([if (constBool) ...?{}])
/*member: listLiteral23:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  SpreadElement(?...SetOrMapLiteral({})))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral23() {}

@Helper([if (constBool) ...?null])
/*member: listLiteral24:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  SpreadElement(?...NullLiteral()))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)*/
void listLiteral24() {}

@Helper([
  if (constBool)
    if (constBool) ?null else ?null,
])
/*member: listLiteral25:
resolved=ListLiteral([IfElement(
  StaticGet(constBool),
  IfElement(
    StaticGet(constBool),
    ExpressionElement(?NullLiteral()),
    ExpressionElement(?NullLiteral())))])
evaluate=ListLiteral([])
constBool=BooleanLiteral(true)
constBool=BooleanLiteral(true)*/
void listLiteral25() {}
