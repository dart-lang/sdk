// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:
 static=[
  testAssert(0),
  testAssertWithMessage(0),
  testForIn(1),
  testForInTyped(1),
  testIfThen(0),
  testIfThenElse(0),
  testSwitchWithoutFallthrough(1),
  testTryCatch(0),
  testTryCatchOn(0),
  testTryCatchStackTrace(0),
  testTryFinally(0)],
  type=[inst:JSNull]
*/
main() {
  testIfThen();
  testIfThenElse();
  testForIn(null);
  testForInTyped(null);
  testTryCatch();
  testTryCatchOn();
  testTryCatchStackTrace();
  testTryFinally();
  testSwitchWithoutFallthrough(null);
  testAssert();
  testAssertWithMessage();
}

/*member: flag=:
 dynamic=[_Cell.value=],
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _#flag,
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  findType(1),
  instanceType(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  param:bool]
*/
/*member: _#flag:
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _Cell.named(1),
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  findType(1),
  instanceType(1),
  throwCyclicInit(1),
  throwLateFieldADI(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  inst:JSString,
  param:_Cell]
*/
late bool flag;

/*member: testIfThen:
 static=[set:flag],
 type=[
  inst:JSBool,
  inst:JSInt,
  inst:JSNumNotInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testIfThen() {
  if (flag = false) return 42;
  return 1;
}

/*member: testIfThenElse:
 static=[set:flag],
 type=[
  inst:JSBool,
  inst:JSInt,
  inst:JSNumNotInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testIfThenElse() {
  if (flag = true)
    return 42;
  else
    return 1;
}

/*member: testForIn:
 dynamic=[
  Iterator.current,
  Iterator.iterator,
  Iterator.moveNext(0)],
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  checkConcurrentModificationError(2),
  findType(1),
  instanceType(1)],
 type=[
  impl:Iterable<dynamic>,
  inst:Closure,
  inst:JSBool,
  inst:JSNull,
  inst:Null]
*/
testForIn(o) {
  // ignore: UNUSED_LOCAL_VARIABLE
  for (var e in o) {}
}

/*member: testForInTyped:
 dynamic=[
  Iterator.current,
  Iterator.iterator,
  Iterator.moveNext(0)],
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  checkConcurrentModificationError(2),
  findType(1),
  instanceType(1)],
 type=[
  impl:Iterable<dynamic>,
  impl:int,
  inst:Closure,
  inst:JSBool,
  inst:JSNull,
  inst:Null]
*/
testForInTyped(o) {
  // ignore: UNUSED_LOCAL_VARIABLE
  for (int e in o) {}
}

/*member: testTryCatch:
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  findType(1),
  instanceType(1),
  unwrapException(1)],
 type=[
  catch:Object,
  inst:Closure,
  inst:JSBool,
  inst:PlainJavaScriptObject,
  inst:UnknownJavaScriptObject]
*/
testTryCatch() {
  try {} catch (e) {}
}

/*member: testTryCatchOn:
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  findType(1),
  instanceType(1),
  unwrapException(1)],
 type=[
  catch:String,
  inst:Closure,
  inst:JSBool,
  inst:PlainJavaScriptObject,
  inst:UnknownJavaScriptObject]
*/
testTryCatchOn() {
  // ignore: UNUSED_CATCH_CLAUSE
  try {} on String catch (e) {}
}

/*member: testTryCatchStackTrace:
 static=[
  Rti._bind(1),
  Rti._eval(1),
  _arrayInstanceType(1),
  _asBool(1),
  _asBoolQ(1),
  _asBoolS(1),
  _asDouble(1),
  _asDoubleQ(1),
  _asDoubleS(1),
  _asInt(1),
  _asIntQ(1),
  _asIntS(1),
  _asNum(1),
  _asNumQ(1),
  _asNumS(1),
  _asObject(1),
  _asString(1),
  _asStringQ(1),
  _asStringS(1),
  _asTop(1),
  _generalAsCheckImplementation(1),
  _generalIsTestImplementation(1),
  _generalNullableAsCheckImplementation(1),
  _generalNullableIsTestImplementation(1),
  _installSpecializedAsCheck(1),
  _installSpecializedIsTest(1),
  _instanceType(1),
  _isBool(1),
  _isInt(1),
  _isNum(1),
  _isObject(1),
  _isString(1),
  _isTop(1),
  findType(1),
  getTraceFromException(1),
  instanceType(1),
  unwrapException(1)],
 type=[
  catch:Object,
  inst:Closure,
  inst:JSBool,
  inst:PlainJavaScriptObject,
  inst:UnknownJavaScriptObject,
  inst:_StackTrace]
*/
testTryCatchStackTrace() {
  // ignore: UNUSED_CATCH_STACK
  try {} catch (e, s) {}
}

/*member: testTryFinally:*/
testTryFinally() {
  try {} finally {}
}

/*member: testSwitchWithoutFallthrough:
 static=[
  throwExpression(1),
  wrapException(1)],
 type=[
  inst:JSInt,
  inst:JSNumNotInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSString,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testSwitchWithoutFallthrough(o) {
  switch (o) {
    case 0:
    case 1:
      o = 2;
      break;
    case 2:
      o = 3;
      return;
    case 3:
      throw '';
    case 4:
    default:
  }
}

/*member: testAssert:static=[assertHelper(1)],type=[inst:JSBool]*/
testAssert() {
  assert(true);
}

/*member: testAssertWithMessage:static=[assertTest(1),assertThrow(1)],type=[inst:JSBool,inst:JSString]*/
testAssertWithMessage() {
  assert(true, 'ok');
}
