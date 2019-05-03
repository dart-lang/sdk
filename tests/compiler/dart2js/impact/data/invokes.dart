// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[
  testClosure(0),
  testClosureInvoke(0),
  testDynamicGet(1),
  testDynamicInvoke(1),
  testDynamicPrivateMethodInvoke(0),
  testDynamicSet(1),
  testInvokeIndex(1),
  testInvokeIndexSet(1),
  testLocalFunction(0),
  testLocalFunctionGet(0),
  testLocalFunctionInvoke(0),
  testLocalFunctionTyped(0),
  testLocalWithInitializer(0),
  testLocalWithInitializerTyped(0),
  testLocalWithoutInitializer(0),
  testStaticFunctionGet(0),
  testTopLevelField(0),
  testTopLevelFieldConst(0),
  testTopLevelFieldFinal(0),
  testTopLevelFieldGeneric1(0),
  testTopLevelFieldGeneric2(0),
  testTopLevelFieldGeneric3(0),
  testTopLevelFieldLazy(0),
  testTopLevelFieldTyped(0),
  testTopLevelFieldWrite(0),
  testTopLevelFunctionGet(0),
  testTopLevelFunctionTyped(0),
  testTopLevelGetterGet(0),
  testTopLevelGetterGetTyped(0),
  testTopLevelInvoke(0),
  testTopLevelInvokeTyped(0),
  testTopLevelSetterSet(0),
  testTopLevelSetterSetTyped(0)],
 type=[inst:JSNull]
*/
main() {
  testTopLevelInvoke();
  testTopLevelInvokeTyped();
  testTopLevelFunctionTyped();
  testTopLevelFunctionGet();
  testTopLevelGetterGet();
  testTopLevelGetterGetTyped();
  testTopLevelSetterSet();
  testTopLevelSetterSetTyped();
  testTopLevelField();
  testTopLevelFieldLazy();
  testTopLevelFieldConst();
  testTopLevelFieldFinal();
  testTopLevelFieldTyped();
  testTopLevelFieldGeneric1();
  testTopLevelFieldGeneric2();
  testTopLevelFieldGeneric3();
  testTopLevelFieldWrite();
  testStaticFunctionGet();
  testDynamicInvoke(null);
  testDynamicGet(null);
  testDynamicSet(null);
  testLocalWithoutInitializer();
  testLocalWithInitializer();
  testLocalWithInitializerTyped();
  testLocalFunction();
  testLocalFunctionTyped();
  testLocalFunctionInvoke();
  testLocalFunctionGet();
  testClosure();
  testClosureInvoke();
  testInvokeIndex(null);
  testInvokeIndexSet(null);
  testDynamicPrivateMethodInvoke();
}

/*element: topLevelFunction1:*/
topLevelFunction1(a) {}

/*element: topLevelFunction2:type=[inst:JSNull]*/
topLevelFunction2(a, [b, c]) {}

/*element: topLevelFunction3:type=[inst:JSNull]*/
topLevelFunction3(a, {b, c}) {}

/*element: testTopLevelInvoke:
 static=[
  topLevelFunction1(1),
  topLevelFunction2(1),
  topLevelFunction2(2),
  topLevelFunction2(3),
  topLevelFunction3(1),
  topLevelFunction3(1,b),
  topLevelFunction3(1,b,c),
  topLevelFunction3(1,b,c),
  topLevelFunction3(1,c)],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testTopLevelInvoke() {
  topLevelFunction1(0);
  topLevelFunction2(1);
  topLevelFunction2(2, 3);
  topLevelFunction2(4, 5, 6);
  topLevelFunction3(7);
  topLevelFunction3(8, b: 9);
  topLevelFunction3(10, c: 11);
  topLevelFunction3(12, b: 13, c: 14);
  topLevelFunction3(15, c: 16, b: 17);
}

/*element: topLevelFunction1Typed:type=[inst:JSBool,param:int]*/
void topLevelFunction1Typed(int a) {}

/*element: topLevelFunction2Typed:
 type=[
  inst:JSBool,
  inst:JSNull,
  param:String,
  param:double,
  param:num]
*/
int topLevelFunction2Typed(String a, [num b, double c]) => null;

/*element: topLevelFunction3Typed:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:List<int>,
  param:Map<String,bool>,
  param:bool]
*/
double topLevelFunction3Typed(bool a, {List<int> b, Map<String, bool> c}) {
  return null;
}

/*element: testTopLevelInvokeTyped:
 static=[
  topLevelFunction1Typed(1),
  topLevelFunction2Typed(1),
  topLevelFunction2Typed(2),
  topLevelFunction2Typed(3),
  topLevelFunction3Typed(1),
  topLevelFunction3Typed(1,b),
  topLevelFunction3Typed(1,b,c),
  topLevelFunction3Typed(1,b,c),
  topLevelFunction3Typed(1,c)],
 type=[
  inst:JSBool,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSString,
  inst:JSUInt31,
  inst:JSUInt32,
  inst:List<int>,
  inst:Map<String,bool>]
*/
testTopLevelInvokeTyped() {
  topLevelFunction1Typed(0);
  topLevelFunction2Typed('1');
  topLevelFunction2Typed('2', 3);
  topLevelFunction2Typed('3', 5, 6.0);
  topLevelFunction3Typed(true);
  topLevelFunction3Typed(false, b: []);
  topLevelFunction3Typed(null, c: {});
  topLevelFunction3Typed(true, b: [13], c: {'14': true});
  topLevelFunction3Typed(false, c: {'16': false}, b: [17]);
}

/*element: topLevelFunctionTyped1:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num)]
*/
topLevelFunctionTyped1(void a(num b)) {}

/*element: topLevelFunctionTyped2:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num,[String])]
*/
topLevelFunctionTyped2(void a(num b, [String c])) {}

/*element: topLevelFunctionTyped3:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num,{String c,int d})]
*/
topLevelFunctionTyped3(void a(num b, {String c, int d})) {}

/*element: topLevelFunctionTyped4:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:void Function(num,{int c,String d})]
*/
topLevelFunctionTyped4(void a(num b, {String d, int c})) {}

/*element: testTopLevelFunctionTyped:
 static=[
  topLevelFunctionTyped1(1),
  topLevelFunctionTyped2(1),
  topLevelFunctionTyped3(1),
  topLevelFunctionTyped4(1)],
 type=[inst:JSNull]
*/
testTopLevelFunctionTyped() {
  topLevelFunctionTyped1(null);
  topLevelFunctionTyped2(null);
  topLevelFunctionTyped3(null);
  topLevelFunctionTyped4(null);
}

/*element: testTopLevelFunctionGet:static=[topLevelFunction1]*/
testTopLevelFunctionGet() => topLevelFunction1;

/*element: topLevelGetter:type=[inst:JSNull]*/
get topLevelGetter => null;

/*element: testTopLevelGetterGet:static=[topLevelGetter]*/
testTopLevelGetterGet() => topLevelGetter;

/*element: topLevelGetterTyped:type=[inst:JSNull]*/
int get topLevelGetterTyped => null;

/*element: testTopLevelGetterGetTyped:static=[topLevelGetterTyped]*/
testTopLevelGetterGetTyped() => topLevelGetterTyped;

/*element: topLevelSetter=:*/
set topLevelSetter(_) {}

/*element: testTopLevelSetterSet:static=[set:topLevelSetter],type=[inst:JSNull]*/
testTopLevelSetterSet() => topLevelSetter = null;

/*element: topLevelSetterTyped=:type=[inst:JSBool,param:int]*/
void set topLevelSetterTyped(int value) {}

/*element: testTopLevelSetterSetTyped:static=[set:topLevelSetterTyped],type=[inst:JSNull]*/
testTopLevelSetterSetTyped() => topLevelSetterTyped = null;

/*element: topLevelField:type=[inst:JSNull]*/
var topLevelField;

/*element: testTopLevelField:static=[topLevelField]*/
testTopLevelField() => topLevelField;

/*element: topLevelFieldLazy:static=[throwCyclicInit(1),topLevelFunction1(1)],type=[inst:JSNull]*/
var topLevelFieldLazy = topLevelFunction1(null);

/*element: testTopLevelFieldLazy:static=[topLevelFieldLazy]*/
testTopLevelFieldLazy() => topLevelFieldLazy;

/*strong.element: topLevelFieldConst:type=[inst:JSNull]*/
const topLevelFieldConst = null;

/*strong.element: testTopLevelFieldConst:static=[topLevelFieldConst]*/
/*strongConst.element: testTopLevelFieldConst:type=[inst:JSNull]*/
testTopLevelFieldConst() => topLevelFieldConst;

/*element: topLevelFieldFinal:static=[throwCyclicInit(1),topLevelFunction1(1)],type=[inst:JSNull]*/
final topLevelFieldFinal = topLevelFunction1(null);

/*element: testTopLevelFieldFinal:static=[topLevelFieldFinal]*/
testTopLevelFieldFinal() => topLevelFieldFinal;

/*element: topLevelFieldTyped:type=[inst:JSBool,inst:JSNull,param:int]*/
int topLevelFieldTyped;

/*element: testTopLevelFieldTyped:static=[topLevelFieldTyped]*/
testTopLevelFieldTyped() => topLevelFieldTyped;

/*element: topLevelFieldGeneric1:type=[inst:JSBool,inst:JSNull,param:GenericClass<dynamic,dynamic>]*/
GenericClass topLevelFieldGeneric1;

/*element: testTopLevelFieldGeneric1:static=[topLevelFieldGeneric1]*/
testTopLevelFieldGeneric1() => topLevelFieldGeneric1;

/*element: topLevelFieldGeneric2:type=[inst:JSBool,inst:JSNull,param:GenericClass<dynamic,dynamic>]*/
GenericClass<dynamic, dynamic> topLevelFieldGeneric2;

/*element: testTopLevelFieldGeneric2:static=[topLevelFieldGeneric2]*/
testTopLevelFieldGeneric2() => topLevelFieldGeneric2;

/*element: topLevelFieldGeneric3:
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:GenericClass<int,String>]
*/
GenericClass<int, String> topLevelFieldGeneric3;

/*element: testTopLevelFieldGeneric3:static=[topLevelFieldGeneric3]*/
testTopLevelFieldGeneric3() => topLevelFieldGeneric3;

/*element: testTopLevelFieldWrite:static=[set:topLevelField],type=[inst:JSNull]*/
testTopLevelFieldWrite() => topLevelField = null;

class StaticFunctionGetClass {
  /*element: StaticFunctionGetClass.foo:*/
  static foo() {}
}

/*element: testStaticFunctionGet:static=[StaticFunctionGetClass.foo]*/
testStaticFunctionGet() => StaticFunctionGetClass.foo;

/*element: testDynamicInvoke:
 dynamic=[
  call(1),
  call(1,b),
  call(1,b,c),
  call(1,b,c),
  call(1,c),
  call(2),
  call(3),
  f1(1),
  f2(1),
  f3(2),
  f4(3),
  f5(1),
  f6(1,b),
  f7(1,c),
  f8(1,b,c),
  f9(1,b,c)],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testDynamicInvoke(o) {
  o.f1(0);
  o.f2(1);
  o.f3(2, 3);
  o.f4(4, 5, 6);
  o.f5(7);
  o.f6(8, b: 9);
  o.f7(10, c: 11);
  o.f8(12, b: 13, c: 14);
  o.f9(15, c: 16, b: 17);
}

/*element: testDynamicGet:dynamic=[foo]*/
testDynamicGet(o) => o.foo;

/*element: testDynamicSet:
 dynamic=[foo=],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testDynamicSet(o) => o.foo = 42;

// TODO(johnniwinther): Remove 'inst:Null'.
/*element: testLocalWithoutInitializer:type=[inst:JSNull,inst:Null]*/
testLocalWithoutInitializer() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var l;
}

/*element: testLocalWithInitializer:
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testLocalWithInitializer() {
  // ignore: UNUSED_LOCAL_VARIABLE
  var l = 42;
}

/*element: testLocalWithInitializerTyped:
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testLocalWithInitializerTyped() {
  // ignore: UNUSED_LOCAL_VARIABLE
  int l = 42;
}

/*element: testLocalFunction:
 static=[
  computeSignature(3),
  def:localFunction,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
 type=[
  inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testLocalFunction() {
  // ignore: UNUSED_ELEMENT
  localFunction() {}
}

/*element: testLocalFunctionTyped:
 static=[
  computeSignature(3),
  def:localFunction,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:String]*/
testLocalFunctionTyped() {
  // ignore: UNUSED_ELEMENT
  int localFunction(String a) => null;
}

/*element: testLocalFunctionInvoke:
 dynamic=[call(0)],
 static=[computeSignature(3),
  def:localFunction,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  localFunction(0),
  setRuntimeTypeInfo(2)],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]*/
testLocalFunctionInvoke() {
  localFunction() {}
  localFunction();
}

/*element: testLocalFunctionGet:static=[computeSignature(3),
  def:localFunction,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]*/
testLocalFunctionGet() {
  localFunction() {}
  localFunction;
}

/*element: testClosure:static=[computeSignature(3),
  def:<anonymous>,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]*/
testClosure() {
  () {};
}

/*element: testClosureInvoke:
 dynamic=[call(0)],
 static=[computeSignature(3),
  def:<anonymous>,
  getRuntimeTypeArguments(3),
  getRuntimeTypeInfo(1),
  setRuntimeTypeInfo(2)],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]
*/
testClosureInvoke() {
  () {}();
}

/*element: testInvokeIndex:
 dynamic=[[]],
 type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testInvokeIndex(o) => o[42];

/*element: testInvokeIndexSet:
 dynamic=[[]=],
 type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testInvokeIndexSet(o) => o[42] = null;

/*element: testDynamicPrivateMethodInvoke:
 dynamic=[_privateMethod(0),call(0)],
 type=[inst:JSNull]
*/
testDynamicPrivateMethodInvoke([o]) => o._privateMethod();

class GenericClass<X, Y> {}
