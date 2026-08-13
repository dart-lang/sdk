// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const int constInt = 42;

const List<int> constList = [2, 3];

@Helper({0})
/*member: setOrMapLiteral1:
resolved=SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))})*/
void setOrMapLiteral1() {}

@Helper({?0})
/*member: setOrMapLiteral2:
resolved=SetOrMapLiteral({ExpressionElement(?IntegerLiteral(0))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(0))})*/
void setOrMapLiteral2() {}

@Helper({?null})
/*member: setOrMapLiteral3:
resolved=SetOrMapLiteral({ExpressionElement(?NullLiteral())})
evaluate=SetOrMapLiteral({})*/
void setOrMapLiteral3() {}

@Helper({?constInt})
/*member: setOrMapLiteral4:
resolved=SetOrMapLiteral({ExpressionElement(?StaticGet(constInt))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(42))})
constInt=IntegerLiteral(42)*/
void setOrMapLiteral4() {}

@Helper({if (true) 1})
/*member: setOrMapLiteral5:
resolved=SetOrMapLiteral({IfElement(
  BooleanLiteral(true),
  ExpressionElement(IntegerLiteral(1)))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(1))})*/
void setOrMapLiteral5() {}

@Helper({if (false) 1})
/*member: setOrMapLiteral6:
resolved=SetOrMapLiteral({IfElement(
  BooleanLiteral(false),
  ExpressionElement(IntegerLiteral(1)))})
evaluate=SetOrMapLiteral({})*/
void setOrMapLiteral6() {}

@Helper({if (constBool) 1})
/*member: setOrMapLiteral7:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  ExpressionElement(IntegerLiteral(1)))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(1))})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral7() {}

@Helper({if (true) 1 else 2})
/*member: setOrMapLiteral8:
resolved=SetOrMapLiteral({IfElement(
  BooleanLiteral(true),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(IntegerLiteral(2)))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(1))})*/
void setOrMapLiteral8() {}

@Helper({if (false) 1 else 2})
/*member: setOrMapLiteral9:
resolved=SetOrMapLiteral({IfElement(
  BooleanLiteral(false),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(IntegerLiteral(2)))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(2))})*/
void setOrMapLiteral9() {}

@Helper({if (constBool) 1 else 2})
/*member: setOrMapLiteral10:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(IntegerLiteral(2)))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(1))})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral10() {}

@Helper({
  ...{0, 1},
})
/*member: setOrMapLiteral11:
resolved=SetOrMapLiteral({SpreadElement(...SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))}))})
evaluate=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))})*/
void setOrMapLiteral11() {}

@Helper({...constList})
/*member: setOrMapLiteral12:
resolved=SetOrMapLiteral({SpreadElement(...StaticGet(constList))})
evaluate=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))})
constList=ListLiteral([
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))])*/
void setOrMapLiteral12() {}

@Helper({
  ...?{0, 1},
})
/*member: setOrMapLiteral13:
resolved=SetOrMapLiteral({SpreadElement(?...SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))}))})
evaluate=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(0)), 
  ExpressionElement(IntegerLiteral(1))})*/
void setOrMapLiteral13() {}

@Helper({...?constList})
/*member: setOrMapLiteral14:
resolved=SetOrMapLiteral({SpreadElement(?...StaticGet(constList))})
evaluate=SetOrMapLiteral({
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))})
constList=ListLiteral([
  ExpressionElement(IntegerLiteral(2)), 
  ExpressionElement(IntegerLiteral(3))])*/
void setOrMapLiteral14() {}

@Helper({...?null})
/*member: setOrMapLiteral15:
resolved=SetOrMapLiteral({SpreadElement(?...NullLiteral())})
evaluate=SetOrMapLiteral({})*/
void setOrMapLiteral15() {}

@Helper({if (constBool) ?null})
/*member: setOrMapLiteral16:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  ExpressionElement(?NullLiteral()))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral16() {}

@Helper({if (constBool) ?null else 2})
/*member: setOrMapLiteral17:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  ExpressionElement(?NullLiteral()),
  ExpressionElement(IntegerLiteral(2)))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral17() {}

@Helper({if (constBool) 1 else ?null})
/*member: setOrMapLiteral18:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  ExpressionElement(IntegerLiteral(1)),
  ExpressionElement(?NullLiteral()))})
evaluate=SetOrMapLiteral({ExpressionElement(IntegerLiteral(1))})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral18() {}

@Helper({if (constBool) ?null else ?null})
/*member: setOrMapLiteral19:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  ExpressionElement(?NullLiteral()),
  ExpressionElement(?NullLiteral()))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral19() {}

@Helper({if (constBool) ...[]})
/*member: setOrMapLiteral20:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  SpreadElement(...ListLiteral([])))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral20() {}

@Helper({if (constBool) ...[]})
/*member: setOrMapLiteral21:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  SpreadElement(...ListLiteral([])))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral21() {}

@Helper({if (constBool) ...?{}})
/*member: setOrMapLiteral22:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  SpreadElement(?...SetOrMapLiteral({})))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral22() {}

@Helper({if (constBool) ...?{}})
/*member: setOrMapLiteral23:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  SpreadElement(?...SetOrMapLiteral({})))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral23() {}

@Helper({if (constBool) ...?null})
/*member: setOrMapLiteral24:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  SpreadElement(?...NullLiteral()))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral24() {}

@Helper({
  if (constBool)
    if (constBool) ?null else ?null,
})
/*member: setOrMapLiteral25:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  IfElement(
    StaticGet(constBool),
    ExpressionElement(?NullLiteral()),
    ExpressionElement(?NullLiteral())))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)
constBool=BooleanLiteral(true)*/
void setOrMapLiteral25() {}

@Helper({0: 1})
/*member: setOrMapLiteral26:
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(1))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(1))})*/
void setOrMapLiteral26() {}

@Helper({?0: 1})
/*member: setOrMapLiteral27:
resolved=SetOrMapLiteral({MapEntryElement(?IntegerLiteral(0):IntegerLiteral(1))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(1))})*/
void setOrMapLiteral27() {}

@Helper({0: ?1})
/*member: setOrMapLiteral28:
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):?IntegerLiteral(1))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(1))})*/
void setOrMapLiteral28() {}

@Helper({?0: ?1})
/*member: setOrMapLiteral29:
resolved=SetOrMapLiteral({MapEntryElement(?IntegerLiteral(0):?IntegerLiteral(1))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(1))})*/
void setOrMapLiteral29() {}

@Helper({?null: 1})
/*member: setOrMapLiteral30:
resolved=SetOrMapLiteral({MapEntryElement(?NullLiteral():IntegerLiteral(1))})
evaluate=SetOrMapLiteral({})*/
void setOrMapLiteral30() {}

@Helper({0: ?null})
/*member: setOrMapLiteral31:
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):?NullLiteral())})
evaluate=SetOrMapLiteral({})*/
void setOrMapLiteral31() {}

@Helper({?null: ?null})
/*member: setOrMapLiteral32:
resolved=SetOrMapLiteral({MapEntryElement(?NullLiteral():?NullLiteral())})
evaluate=SetOrMapLiteral({})*/
void setOrMapLiteral32() {}

@Helper({?constInt: 1})
/*member: setOrMapLiteral33:
resolved=SetOrMapLiteral({MapEntryElement(?StaticGet(constInt):IntegerLiteral(1))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(42):IntegerLiteral(1))})
constInt=IntegerLiteral(42)*/
void setOrMapLiteral33() {}

@Helper({0: ?constInt})
/*member: setOrMapLiteral34:
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):?StaticGet(constInt))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(42))})
constInt=IntegerLiteral(42)*/
void setOrMapLiteral34() {}

@Helper({?constInt: ?constInt})
/*member: setOrMapLiteral35:
resolved=SetOrMapLiteral({MapEntryElement(?StaticGet(constInt):?StaticGet(constInt))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(42):IntegerLiteral(42))})
constInt=IntegerLiteral(42)
constInt=IntegerLiteral(42)*/
void setOrMapLiteral35() {}

@Helper({if (constBool) ?null: 1})
/*member: setOrMapLiteral36:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(?NullLiteral():IntegerLiteral(1)))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral36() {}

@Helper({if (constBool) 0: ?null})
/*member: setOrMapLiteral37:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(IntegerLiteral(0):?NullLiteral()))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral37() {}

@Helper({if (constBool) ?null: ?null})
/*member: setOrMapLiteral38:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(?NullLiteral():?NullLiteral()))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral38() {}

@Helper({if (constBool) ?null: 1 else 2: 3})
/*member: setOrMapLiteral39:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(?NullLiteral():IntegerLiteral(1)),
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(3)))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral39() {}

@Helper({if (constBool) 0: ?null else 2: 3})
/*member: setOrMapLiteral40:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(IntegerLiteral(0):?NullLiteral()),
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(3)))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral40() {}

@Helper({if (constBool) ?null: ?null else 2: 3})
/*member: setOrMapLiteral41:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(?NullLiteral():?NullLiteral()),
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(3)))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral41() {}

@Helper({if (constBool) 1: 2 else ?null: 3})
/*member: setOrMapLiteral42:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(2)),
  MapEntryElement(?NullLiteral():IntegerLiteral(3)))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(1):IntegerLiteral(2))})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral42() {}

@Helper({if (constBool) 1: 2 else 3: ?null})
/*member: setOrMapLiteral43:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(2)),
  MapEntryElement(IntegerLiteral(3):?NullLiteral()))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(1):IntegerLiteral(2))})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral43() {}

@Helper({if (constBool) 1: 2 else ?null: ?null})
/*member: setOrMapLiteral44:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(2)),
  MapEntryElement(?NullLiteral():?NullLiteral()))})
evaluate=SetOrMapLiteral({MapEntryElement(IntegerLiteral(1):IntegerLiteral(2))})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral44() {}

@Helper({if (constBool) ?null: 1 else ?null: 2})
/*member: setOrMapLiteral45:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(?NullLiteral():IntegerLiteral(1)),
  MapEntryElement(?NullLiteral():IntegerLiteral(2)))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral45() {}

@Helper({if (constBool) 1: ?null else 2: ?null})
/*member: setOrMapLiteral46:
resolved=SetOrMapLiteral({IfElement(
  StaticGet(constBool),
  MapEntryElement(IntegerLiteral(1):?NullLiteral()),
  MapEntryElement(IntegerLiteral(2):?NullLiteral()))})
evaluate=SetOrMapLiteral({})
constBool=BooleanLiteral(true)*/
void setOrMapLiteral46() {}
