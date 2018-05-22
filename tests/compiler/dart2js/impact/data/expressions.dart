// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:static=[
  testAs(0),
  testAsGeneric(0),
  testAsGenericDynamic(0),
  testAsGenericRaw(0),
  testConditional(0),
  testIfNotNull(1),
  testIfNotNullSet(1),
  testIfNull(1),
  testIs(0),
  testIsGeneric(0),
  testIsGenericDynamic(0),
  testIsGenericRaw(0),
  testIsNot(0),
  testIsNotGeneric(0),
  testIsNotGenericDynamic(0),
  testIsNotGenericRaw(0),
  testIsTypedef(0),
  testIsTypedefDeep(0),
  testIsTypedefGeneric(0),
  testIsTypedefGenericDynamic(0),
  testIsTypedefGenericRaw(0),
  testNot(0),
  testPostDec(1),
  testPostInc(1),
  testPreDec(1),
  testPreInc(1),
  testSetIfNull(1),
  testThrow(0),
  testUnaryMinus(0)
],type=[inst:JSNull]
 */
main() {
  testNot();
  testUnaryMinus();
  testConditional();
  testPostInc(null);
  testPostDec(null);
  testPreInc(null);
  testPreDec(null);
  testIs();
  testIsGeneric();
  testIsGenericRaw();
  testIsGenericDynamic();
  testIsNot();
  testIsNotGeneric();
  testIsNotGenericRaw();
  testIsNotGenericDynamic();
  testIsTypedef();
  testIsTypedefGeneric();
  testIsTypedefGenericRaw();
  testIsTypedefGenericDynamic();
  testIsTypedefDeep();
  testAs();
  testAsGeneric();
  testAsGenericRaw();
  testAsGenericDynamic();
  testThrow();
  testIfNotNull(null);
  testIfNotNullSet(null);
  testIfNull(null);
  testSetIfNull(null);
}

/*element: testNot:type=[inst:JSBool]*/
testNot() => !false;

/*element: testUnaryMinus:
 dynamic=[unary-],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testUnaryMinus() => -1;

/*element: testConditional:type=[inst:JSBool,inst:JSNull,inst:JSString]*/
// ignore: DEAD_CODE
testConditional() => true ? null : '';

/*element: testPostInc:
 dynamic=[+],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPostInc(o) => o++;

/*element: testPostDec:
 dynamic=[-],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPostDec(o) => o--;

/*element: testPreInc:
 dynamic=[+],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPreInc(o) => ++o;

/*element: testPreDec:
 dynamic=[-],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testPreDec(o) => --o;

/*element: testIs:type=[inst:JSBool,inst:JSNull,is:Class]*/
testIs() => null is Class;

/*element: testIsGeneric:
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
  is:GenericClass<int,String>]
 */
testIsGeneric() => null is GenericClass<int, String>;

/*element: testIsGenericRaw:
 type=[inst:JSBool,inst:JSNull,is:GenericClass<dynamic,dynamic>]
*/
testIsGenericRaw() => null is GenericClass;

/*element: testIsGenericDynamic:
 type=[inst:JSBool,inst:JSNull,is:GenericClass<dynamic,dynamic>]
*/
testIsGenericDynamic() => null is GenericClass<dynamic, dynamic>;

/*element: testIsNot:type=[inst:JSBool,inst:JSNull,is:Class]*/
testIsNot() => null is! Class;

/*element: testIsNotGeneric:
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
  is:GenericClass<int,String>]
*/
testIsNotGeneric() => null is! GenericClass<int, String>;

/*element: testIsNotGenericRaw:
 type=[inst:JSBool,inst:JSNull,is:GenericClass<dynamic,dynamic>]
*/
testIsNotGenericRaw() => null is! GenericClass;

/*element: testIsNotGenericDynamic:
 type=[inst:JSBool,inst:JSNull,is:GenericClass<dynamic,dynamic>]
*/
testIsNotGenericDynamic() => null is! GenericClass<dynamic, dynamic>;

/*element: testIsTypedef:
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
  is:dynamic Function()]
*/
testIsTypedef() => null is Typedef;

/*element: testIsTypedefGeneric:
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
  is:int Function(String)]*/
testIsTypedefGeneric() => null is GenericTypedef<int, String>;

/*element: testIsTypedefGenericRaw:
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
  is:dynamic Function(dynamic)]*/
testIsTypedefGenericRaw() => null is GenericTypedef;

/*element: testIsTypedefGenericDynamic:
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
  is:dynamic Function(dynamic)]*/
testIsTypedefGenericDynamic() => null is GenericTypedef<dynamic, dynamic>;

/*element: testIsTypedefDeep:
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
  is:List<int Function(dynamic Function(dynamic))>]*/
testIsTypedefDeep() => null is List<GenericTypedef<int, GenericTypedef>>;

/*element: testAs:
 static=[throwRuntimeError],
 type=[as:Class,inst:JSBool,inst:JSNull]
*/
// ignore: UNNECESSARY_CAST
testAs() => null as Class;

/*element: testAsGeneric:static=[checkSubtype,
  getRuntimeTypeArgument,
  getRuntimeTypeArgumentIntercepted,
  getRuntimeTypeInfo,
  getTypeArgumentByIndex,
  setRuntimeTypeInfo,
  throwRuntimeError],
  type=[as:GenericClass<int,
  String>,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>]*/
// ignore: UNNECESSARY_CAST
testAsGeneric() => null as GenericClass<int, String>;

/*element: testAsGenericRaw:
 static=[throwRuntimeError],
 type=[as:GenericClass<dynamic,dynamic>,inst:JSBool,inst:JSNull]
*/
// ignore: UNNECESSARY_CAST
testAsGenericRaw() => null as GenericClass;

/*element: testAsGenericDynamic:
 static=[throwRuntimeError],
 type=[as:GenericClass<dynamic,dynamic>,inst:JSBool,inst:JSNull]
*/
// ignore: UNNECESSARY_CAST
testAsGenericDynamic() => null as GenericClass<dynamic, dynamic>;

/*element: testThrow:
 static=[throwExpression,wrapException],
 type=[inst:JSString]*/
testThrow() => throw '';

/*element: testIfNotNull:dynamic=[==,foo],type=[inst:JSNull]*/
testIfNotNull(o) => o?.foo;

/*element: testIfNotNullSet:dynamic=[==,foo=],type=[inst:JSBool,inst:JSNull]*/
testIfNotNullSet(o) => o?.foo = true;

/*element: testIfNull:dynamic=[==],type=[inst:JSBool,inst:JSNull]*/
testIfNull(o) => o ?? true;

/*element: testSetIfNull:dynamic=[==],type=[inst:JSBool,inst:JSNull]*/
testSetIfNull(o) => o ??= true;

class Class {}

class GenericClass<X, Y> {}

typedef Typedef();

typedef X GenericTypedef<X, Y>(Y y);
