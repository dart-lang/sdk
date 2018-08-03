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

/*kernel.element: topLevelFunction1Typed:type=[check:int,check:void]*/
/*strong.element: topLevelFunction1Typed:type=[inst:JSBool,param:int]*/
void topLevelFunction1Typed(int a) {}

/*kernel.element: topLevelFunction2Typed:
 type=[
  check:String,
  check:double,
  check:int,
  check:num,
  inst:JSNull]
*/
/*strong.element: topLevelFunction2Typed:
 type=[
  inst:JSBool,
  inst:JSNull,
  param:String,
  param:double,
  param:num]
*/
int topLevelFunction2Typed(String a, [num b, double c]) => null;

/*kernel.element: topLevelFunction3Typed:
 type=[
  check:List<int>,
  check:Map<String,bool>,
  check:bool,
  check:double,
  inst:JSNull]
*/
/*strong.element: topLevelFunction3Typed:
 static=[
  checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
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

/*kernel.element: testTopLevelInvokeTyped:
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
  inst:List<dynamic>,
  inst:Map<dynamic,dynamic>]
*/
/*strong.element: testTopLevelInvokeTyped:
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

/*kernel.element: topLevelFunctionTyped1:type=[check:void Function(num)]*/
/*strong.element: topLevelFunctionTyped1:
 static=[
  checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
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

/*kernel.element: topLevelFunctionTyped2:type=[check:void Function(num,[String])]*/
/*strong.element: topLevelFunctionTyped2:
 static=[
  checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
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

/*kernel.element: topLevelFunctionTyped3:
 type=[check:void Function(num,{String c,int d})]
*/
/*strong.element: topLevelFunctionTyped3:
 static=[
  checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
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

/*kernel.element: topLevelFunctionTyped4:
 type=[check:void Function(num,{int c,String d})]
*/
/*strong.element: topLevelFunctionTyped4:
 static=[
  checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
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

/*kernel.element: topLevelGetterTyped:type=[check:int,inst:JSNull]*/
/*strong.element: topLevelGetterTyped:type=[inst:JSNull]*/
int get topLevelGetterTyped => null;

/*element: testTopLevelGetterGetTyped:static=[topLevelGetterTyped]*/
testTopLevelGetterGetTyped() => topLevelGetterTyped;

/*element: topLevelSetter=:*/
set topLevelSetter(_) {}

/*element: testTopLevelSetterSet:static=[set:topLevelSetter],type=[inst:JSNull]*/
testTopLevelSetterSet() => topLevelSetter = null;

/*kernel.element: topLevelSetterTyped=:type=[check:int,check:void]*/
/*strong.element: topLevelSetterTyped=:type=[inst:JSBool,param:int]*/
void set topLevelSetterTyped(int value) {}

/*element: testTopLevelSetterSetTyped:static=[set:topLevelSetterTyped],type=[inst:JSNull]*/
testTopLevelSetterSetTyped() => topLevelSetterTyped = null;

/*element: topLevelField:type=[inst:JSNull]*/
var topLevelField;

/*element: testTopLevelField:static=[topLevelField]*/
testTopLevelField() => topLevelField;

/*element: topLevelFieldLazy:static=[throwCyclicInit,topLevelFunction1(1)],type=[inst:JSNull]*/
var topLevelFieldLazy = topLevelFunction1(null);

/*element: testTopLevelFieldLazy:static=[topLevelFieldLazy]*/
testTopLevelFieldLazy() => topLevelFieldLazy;

/*element: topLevelFieldConst:type=[inst:JSNull]*/
const topLevelFieldConst = null;

/*element: testTopLevelFieldConst:static=[topLevelFieldConst]*/
testTopLevelFieldConst() => topLevelFieldConst;

/*element: topLevelFieldFinal:static=[throwCyclicInit,topLevelFunction1(1)],type=[inst:JSNull]*/
final topLevelFieldFinal = topLevelFunction1(null);

/*element: testTopLevelFieldFinal:static=[topLevelFieldFinal]*/
testTopLevelFieldFinal() => topLevelFieldFinal;

/*kernel.element: topLevelFieldTyped:type=[check:int,inst:JSNull]*/
/*strong.element: topLevelFieldTyped:type=[inst:JSBool,inst:JSNull,param:int]*/
int topLevelFieldTyped;

/*element: testTopLevelFieldTyped:static=[topLevelFieldTyped]*/
testTopLevelFieldTyped() => topLevelFieldTyped;

/*kernel.element: topLevelFieldGeneric1:type=[check:GenericClass<dynamic,dynamic>,inst:JSNull]*/
/*strong.element: topLevelFieldGeneric1:type=[inst:JSBool,inst:JSNull,param:GenericClass<dynamic,dynamic>]*/
GenericClass topLevelFieldGeneric1;

/*element: testTopLevelFieldGeneric1:static=[topLevelFieldGeneric1]*/
testTopLevelFieldGeneric1() => topLevelFieldGeneric1;

/*kernel.element: topLevelFieldGeneric2:type=[check:GenericClass<dynamic,dynamic>,inst:JSNull]*/
/*strong.element: topLevelFieldGeneric2:type=[inst:JSBool,inst:JSNull,param:GenericClass<dynamic,dynamic>]*/
GenericClass<dynamic, dynamic> topLevelFieldGeneric2;

/*element: testTopLevelFieldGeneric2:static=[topLevelFieldGeneric2]*/
testTopLevelFieldGeneric2() => topLevelFieldGeneric2;

/*kernel.element: topLevelFieldGeneric3:type=[check:GenericClass<int,String>,inst:JSNull]*/
/*strong.element: topLevelFieldGeneric3:
 static=[
  checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo],
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

/*kernel.element: testLocalWithInitializerTyped:
 type=[
  check:int,
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
/*strong.element: testLocalWithInitializerTyped:
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

/*kernel.element: testLocalFunction:static=[def:localFunction],type=[inst:Function]*/
/*strong.element: testLocalFunction:
 static=[
  computeSignature,
  def:localFunction,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
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

/*kernel.element: testLocalFunctionTyped:
 static=[def:localFunction],
 type=[check:String,check:int,inst:Function,inst:JSNull]
*/
/*strong.element: testLocalFunctionTyped:
 static=[
  computeSignature,
  def:localFunction,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
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

/*kernel.element: testLocalFunctionInvoke:static=[def:localFunction],
  type=[inst:Function]*/
/*strong.element: testLocalFunctionInvoke:static=[computeSignature,
  def:localFunction,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  localFunction(0),
  setRuntimeTypeInfo],
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

/*kernel.element: testLocalFunctionGet:static=[def:localFunction],
  type=[inst:Function]*/
/*strong.element: testLocalFunctionGet:static=[computeSignature,
  def:localFunction,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
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

/*kernel.element: testClosure:static=[def:<anonymous>],
  type=[inst:Function]*/
/*strong.element: testClosure:static=[computeSignature,
  def:<anonymous>,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]*/
testClosure() {
  () {};
}

/*kernel.element: testClosureInvoke:dynamic=[call(0)],
  static=[def:<anonymous>],
  type=[inst:Function]*/
/*strong.element: testClosureInvoke:dynamic=[call(0)],
  static=[computeSignature,
  def:<anonymous>,
  getRuntimeTypeArguments,
  getRuntimeTypeInfo,
  setRuntimeTypeInfo],
  type=[inst:Function,
  inst:JSArray<dynamic>,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>]*/
testClosureInvoke() {
  () {}();
}

/*element: testInvokeIndex:dynamic=[[]],
  type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]*/
testInvokeIndex(o) => o[42];

/*element: testInvokeIndexSet:dynamic=[[]=],
  type=[inst:JSDouble,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]*/
testInvokeIndexSet(o) => o[42] = null;

/*element: testDynamicPrivateMethodInvoke:dynamic=[_privateMethod(0)],type=[inst:JSNull]*/
testDynamicPrivateMethodInvoke([o]) => o._privateMethod();

class GenericClass<X, Y> {}
