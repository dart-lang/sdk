// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Helper {
  const Helper(a);
}

const bool constBool = true;

const Map<int, int>? constNullableMap = {};

@Helper({})
/*member: mapLiterals1:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({}))))
resolved=SetOrMapLiteral({})*/
void mapLiterals1() {}

@Helper({0: 0})
/*member: mapLiterals2:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))}))))
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))})*/
void mapLiterals2() {}

@Helper({0: 0, 1: 1})
/*member: mapLiterals3:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))})*/
void mapLiterals3() {}

@Helper({0: 0, 1: 1, 2: 2})
/*member: mapLiterals4:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))})*/
void mapLiterals4() {}

@Helper(<int, int>{})
/*member: mapLiterals5:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{}))))
resolved=SetOrMapLiteral(<int,int>{})*/
void mapLiterals5() {}

@Helper(<int, int>{0: 0})
/*member: mapLiterals6:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))}))))
resolved=SetOrMapLiteral(<int,int>{MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))})*/
void mapLiterals6() {}

@Helper(<int, int>{0: 0, 1: 1})
/*member: mapLiterals7:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))})*/
void mapLiterals7() {}

@Helper(<int, int>{0: 0, 1: 1, 2: 2})
/*member: mapLiterals8:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))})*/
void mapLiterals8() {}

@Helper(<int, int>{0: 0, 1: 1, ...{}})
/*member: mapLiterals9:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    SpreadElement(...SetOrMapLiteral({}))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(...SetOrMapLiteral({}))})*/
void mapLiterals9() {}

@Helper(<int, int>{
  0: 0,
  1: 1,
  ...{2: 2, 3: 3},
})
/*member: mapLiterals10:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    SpreadElement(...SetOrMapLiteral({
      MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)), 
      MapEntryElement(IntegerLiteral(3):IntegerLiteral(3))}))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(...SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)), 
    MapEntryElement(IntegerLiteral(3):IntegerLiteral(3))}))})*/
void mapLiterals10() {}

@Helper(<int, int>{0: 0, 1: 1, ...?constNullableMap})
/*member: mapLiterals11:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    SpreadElement(?...UnresolvedExpression(UnresolvedIdentifier(constNullableMap)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  SpreadElement(?...StaticGet(constNullableMap))})*/
void mapLiterals11() {}

@Helper(<int, int>{0: 0, 1: 1, if (constBool) 2: 2})
/*member: mapLiterals12:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  IfElement(
    StaticGet(constBool),
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)))})*/
void mapLiterals12() {}

@Helper(<int, int>{0: 0, 1: 1, if (constBool) 2: 2 else 3: 3})
/*member: mapLiterals13:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    IfElement(
      UnresolvedExpression(UnresolvedIdentifier(constBool)),
      MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)),
      MapEntryElement(IntegerLiteral(3):IntegerLiteral(3)))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  IfElement(
    StaticGet(constBool),
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2)),
    MapEntryElement(IntegerLiteral(3):IntegerLiteral(3)))})*/
void mapLiterals13() {}

@Helper(const {})
/*member: mapLiterals14:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({}))))
resolved=SetOrMapLiteral({})*/
void mapLiterals14() {}

@Helper(const {0: 0})
/*member: mapLiterals15:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))}))))
resolved=SetOrMapLiteral({MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))})*/
void mapLiterals15() {}

@Helper(const {0: 0, 1: 1})
/*member: mapLiterals16:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))})*/
void mapLiterals16() {}

@Helper(const {0: 0, 1: 1, 2: 2})
/*member: mapLiterals17:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral({
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))}))))
resolved=SetOrMapLiteral({
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))})*/
void mapLiterals17() {}

@Helper(const <int, int>{})
/*member: mapLiterals18:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{}))))
resolved=SetOrMapLiteral(<int,int>{})*/
void mapLiterals18() {}

@Helper(const <int, int>{0: 0})
/*member: mapLiterals19:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))}))))
resolved=SetOrMapLiteral(<int,int>{MapEntryElement(IntegerLiteral(0):IntegerLiteral(0))})*/
void mapLiterals19() {}

@Helper(const <int, int>{0: 0, 1: 1})
/*member: mapLiterals20:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1))})*/
void mapLiterals20() {}

@Helper(const <int, int>{0: 0, 1: 1, 2: 2})
/*member: mapLiterals21:
unresolved=UnresolvedExpression(UnresolvedInvoke(
  UnresolvedIdentifier(Helper)
  (SetOrMapLiteral(<{unresolved-type-annotation:UnresolvedIdentifier(int)},{unresolved-type-annotation:UnresolvedIdentifier(int)}>{
    MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
    MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
    MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))}))))
resolved=SetOrMapLiteral(<int,int>{
  MapEntryElement(IntegerLiteral(0):IntegerLiteral(0)), 
  MapEntryElement(IntegerLiteral(1):IntegerLiteral(1)), 
  MapEntryElement(IntegerLiteral(2):IntegerLiteral(2))})*/
void mapLiterals21() {}
