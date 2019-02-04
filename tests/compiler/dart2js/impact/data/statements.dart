// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
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

/*element: testIfThen:
 type=[
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testIfThen() {
  // ignore: DEAD_CODE
  if (false) return 42;
  return 1;
}

/*element: testIfThenElse:
 type=[
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testIfThenElse() {
  if (true)
    return 42;
  else
    // ignore: DEAD_CODE
    return 1;
}

/*strong.element: testForIn:
 dynamic=[
  current,
  iterator,
  moveNext(0)],
 static=[checkConcurrentModificationError(2)],
 type=[
  impl:Iterable<dynamic>,
  inst:JSBool,
  inst:JSNull,
  inst:Null]
*/
testForIn(o) {
  // ignore: UNUSED_LOCAL_VARIABLE
  for (var e in o) {}
}

/*strong.element: testForInTyped:
 dynamic=[
  current,
  iterator,
  moveNext(0)],
 static=[checkConcurrentModificationError(2)],
 type=[
  impl:Iterable<dynamic>,
  impl:int,
  inst:JSBool,
  inst:JSNull,
  inst:Null]
*/
testForInTyped(o) {
  // ignore: UNUSED_LOCAL_VARIABLE
  for (int e in o) {}
}

/*element: testTryCatch:
 static=[unwrapException(1)],
 type=[
  inst:PlainJavaScriptObject,
  inst:UnknownJavaScriptObject]
*/
testTryCatch() {
  try {} catch (e) {}
}

/*element: testTryCatchOn:
 static=[unwrapException(1)],
 type=[
  catch:String,
  inst:JSBool,
  inst:PlainJavaScriptObject,
  inst:UnknownJavaScriptObject]
*/
testTryCatchOn() {
  // ignore: UNUSED_CATCH_CLAUSE
  try {} on String catch (e) {}
}

/*element: testTryCatchStackTrace:
 static=[
  getTraceFromException(1),
  unwrapException(1)],
 type=[
  inst:PlainJavaScriptObject,
  inst:UnknownJavaScriptObject,
  inst:_StackTrace]
*/
testTryCatchStackTrace() {
  // ignore: UNUSED_CATCH_STACK
  try {} catch (e, s) {}
}

/*element: testTryFinally:*/
testTryFinally() {
  try {} finally {}
}

/*element: testSwitchWithoutFallthrough:
 static=[
  throwExpression(1),
  wrapException(1)],
 type=[
  inst:JSDouble,
  inst:JSInt,
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

/*element: testAssert:static=[assertHelper(1)],type=[inst:JSBool]*/
testAssert() {
  assert(true);
}

/*element: testAssertWithMessage:static=[assertTest(1),assertThrow(1)],type=[inst:JSBool,inst:JSString]*/
testAssertWithMessage() {
  assert(true, 'ok');
}
