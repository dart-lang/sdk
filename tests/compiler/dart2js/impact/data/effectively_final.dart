// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[
  effectivelyFinalList(0),
  effectivelyFinalPromoted(0),
  effectivelyFinalPromotedInvalid(0),
  notEffectivelyFinalList(0)]
*/
main() {
  effectivelyFinalList();
  notEffectivelyFinalList();
  effectivelyFinalPromoted();
  effectivelyFinalPromotedInvalid();
}

/*element: effectivelyFinalList:
 dynamic=[
  List.add(1),
  List.length,
  List.length=,
  int.+],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32,
  inst:List<dynamic>]
*/
effectivelyFinalList() {
  dynamic c = [];
  c.add(null);
  c.length + 1;
  c.length = 1;
}

/*element: notEffectivelyFinalList:
 dynamic=[
  +,
  add(1),
  call(1),
  length,
  length=],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32,
  inst:List<dynamic>]
*/
notEffectivelyFinalList() {
  dynamic c = [];
  c.add(null);
  c.length + 1;
  c.length = 1;
  c = null;
}

/*element: _method1:type=[inst:JSNull]*/
num _method1() => null;

/*element: effectivelyFinalPromoted:
 dynamic=[int.+,num.+],
 static=[_method1(0)],
 type=[
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32,
  is:int]
*/
effectivelyFinalPromoted() {
  dynamic c = _method1();
  c + 0;
  if (c is int) {
    c + 1;
  }
}

/*element: _method2:type=[inst:JSNull]*/
String _method2() => null;

/*element: effectivelyFinalPromotedInvalid:
 dynamic=[String.+,int.+],
 static=[_method2(0)],
 type=[
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSString,
  inst:JSUInt31,
  inst:JSUInt32,
  is:int]
*/
effectivelyFinalPromotedInvalid() {
  dynamic c = _method2();
  c + '';
  if (c is int) {
    c + 1;
  }
}
