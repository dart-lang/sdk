// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:static=[
 testBoolFromEnvironment(0),
 testComplexConstSymbol(0),
 testConstSymbol(0),
 testDouble(0),
 testEmpty(0),
 testEmptyListLiteral(0),
 testEmptyListLiteralConstant(0),
 testEmptyListLiteralDynamic(0),
 testEmptyListLiteralTyped(0),
 testEmptyMapLiteral(0),
 testEmptyMapLiteralConstant(0),
 testEmptyMapLiteralDynamic(0),
 testEmptyMapLiteralTyped(0),
 testFalse(0),
 testIfNullConstSymbol(0),
 testInt(0),
 testNonEmptyListLiteral(0),
 testNonEmptyMapLiteral(0),
 testNull(0),
 testString(0),
 testStringInterpolation(0),
 testStringInterpolationConst(0),
 testStringJuxtaposition(0),
 testSymbol(0),
 testTrue(0),
 testTypeLiteral(0)]
*/
main() {
  testEmpty();
  testNull();
  testTrue();
  testFalse();
  testInt();
  testDouble();
  testString();
  testStringInterpolation();
  testStringInterpolationConst();
  testStringJuxtaposition();
  testSymbol();
  testConstSymbol();
  testComplexConstSymbol();
  testIfNullConstSymbol();
  testTypeLiteral();
  testBoolFromEnvironment();
  testEmptyListLiteral();
  testEmptyListLiteralDynamic();
  testEmptyListLiteralTyped();
  testEmptyListLiteralConstant();
  testNonEmptyListLiteral();
  testEmptyMapLiteral();
  testEmptyMapLiteralDynamic();
  testEmptyMapLiteralTyped();
  testEmptyMapLiteralConstant();
  testNonEmptyMapLiteral();
}

/*element: testEmpty:*/
testEmpty() {}

/*element: testNull:type=[inst:JSNull]*/
testNull() => null;

/*element: testTrue:type=[inst:JSBool]*/
testTrue() => true;

/*element: testFalse:type=[inst:JSBool]*/
testFalse() => false;

/*element: testInt:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
testInt() => 42;

/*element: testDouble:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
testDouble() => 37.5;

/*element: testString:type=[inst:JSString]*/
testString() => 'foo';

/*element: testStringInterpolation:
 dynamic=[toString(0)],
 static=[S(1)],type=[inst:JSBool,inst:JSString]
*/
testStringInterpolation() => '${true}';

/*strong.element: testStringInterpolationConst:
 dynamic=[toString(0)],
 static=[S(1)],type=[inst:JSBool,inst:JSString]
*/
/*strongConst.element: testStringInterpolationConst:constant=["true"]*/
testStringInterpolationConst() {
  const b = '${true}';
  return b;
}

/*element: testStringJuxtaposition:
 dynamic=[toString(0)],
 static=[S(1)],
 type=[inst:JSString]
*/
testStringJuxtaposition() => 'a' 'b';

/*strong.element: testSymbol:static=[Symbol.(1)],type=[inst:Symbol]*/
/*strongConst.element: testSymbol:constant=[Symbol(_name="main")]*/
testSymbol() => #main;

/*strong.element: testConstSymbol:
 static=[Symbol.(1),Symbol.(1),Symbol.validated(1)],
 type=[inst:JSString,inst:Symbol]
*/
/*strongConst.element: testConstSymbol:constant=[Symbol(_name="main")]*/
testConstSymbol() => const Symbol('main');

/*strong.element: complexSymbolField1:
 dynamic=[String.length,int.==],
 type=[inst:JSBool,inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSString,inst:JSUInt31,inst:JSUInt32,param:bool]
*/
const complexSymbolField1 = "true".length == 4;

/*strong.element: complexSymbolField2:
 dynamic=[toString(0)],
 static=[S(1)],
 type=[inst:JSBool,inst:JSNull,inst:JSString,param:String]
*/
const complexSymbolField2 = "true" "false" "${true}${null}";

/*strong.element: complexSymbolField3:
  dynamic=[int.+,int.unary-],
  static=[
   GenericClass.generative(0),
   String.fromEnvironment(1),
   Symbol.(1),
   assertIsSubtype(5),
   bool.fromEnvironment(1,defaultValue),
   checkSubtype(4),
   getRuntimeTypeArgument(3),
   getRuntimeTypeArgumentIntercepted(4),
   getRuntimeTypeInfo(1),
   getTypeArgumentByIndex(2),
   identical(2),
   int.fromEnvironment(1,defaultValue),
   override,
   setRuntimeTypeInfo(2),
   testComplexConstSymbol,
   throwTypeError(1)],
  type=[
   inst:ConstantMap<dynamic,dynamic>,
   inst:ConstantProtoMap<dynamic,dynamic>,
   inst:ConstantStringMap<dynamic,dynamic>,
   inst:GeneralConstantMap<dynamic,dynamic>,
   inst:JSArray<dynamic>,
   inst:JSBool,
   inst:JSDouble,
   inst:JSExtendableArray<dynamic>,
   inst:JSFixedArray<dynamic>,
   inst:JSInt,
   inst:JSMutableArray<dynamic>,
   inst:JSNumber,
   inst:JSPositiveInt,
   inst:JSString,
   inst:JSUInt31,
   inst:JSUInt32,
   inst:JSUnmodifiableArray<dynamic>,
   inst:List<int>,
   inst:Symbol,
   param:Map<Object,Object>]
*/
const complexSymbolField3 = const {
  0: const bool.fromEnvironment('a', defaultValue: true),
  false: const int.fromEnvironment('b', defaultValue: 42),
  const <int>[]: const String.fromEnvironment('c'),
  testComplexConstSymbol: #testComplexConstSymbol,
  1 + 2: identical(0, -0),
  // ignore: dead_code
  true || false: false && true,
  override: const GenericClass<int, String>.generative(),
};

/*strong.element: complexSymbolField:
 static=[
  complexSymbolField1,
  complexSymbolField2,
  complexSymbolField3],
 type=[inst:JSBool,param:Object]
*/
const complexSymbolField =
    complexSymbolField1 ? complexSymbolField2 : complexSymbolField3;

/*strong.element: testComplexConstSymbol:
 static=[Symbol.(1),Symbol.(1),Symbol.validated(1),complexSymbolField],
 type=[impl:String,inst:JSBool,inst:Symbol]
*/
/*strongConst.element: testComplexConstSymbol:constant=[Symbol(_name="truefalsetruenull")]*/
testComplexConstSymbol() => const Symbol(complexSymbolField);

/*strong.element: testIfNullConstSymbol:
 dynamic=[Null.==],
 static=[Symbol.(1),Symbol.(1),Symbol.validated(1)],
 type=[inst:JSNull,inst:JSString,inst:Symbol]
*/
/*strongConst.element: testIfNullConstSymbol:constant=[Symbol(_name="foo")]*/
testIfNullConstSymbol() => const Symbol(null ?? 'foo');

/*element: testTypeLiteral:
 static=[createRuntimeType(1)],
 type=[inst:Type,inst:TypeImpl,lit:Object]
*/
testTypeLiteral() => Object;

/*strong.element: testBoolFromEnvironment:static=[bool.fromEnvironment(1)],type=[inst:JSString]*/
/*strongConst.element: testBoolFromEnvironment:constant=[false]*/
testBoolFromEnvironment() => const bool.fromEnvironment('FOO');

/*element: testEmptyListLiteral:type=[inst:List<dynamic>]*/
testEmptyListLiteral() => [];

/*element: testEmptyListLiteralDynamic:type=[inst:List<dynamic>]*/
testEmptyListLiteralDynamic() => <dynamic>[];

/*element: testEmptyListLiteralTyped:type=[inst:List<String>]*/
testEmptyListLiteralTyped() => <String>[];

/*strong.element: testEmptyListLiteralConstant:type=[inst:List<dynamic>]*/
/*strongConst.element: testEmptyListLiteralConstant:constant=[[]]*/
testEmptyListLiteralConstant() => const [];

/*element: testNonEmptyListLiteral:type=[inst:JSBool,inst:List<bool>]*/
testNonEmptyListLiteral() => [true];

/*element: testEmptyMapLiteral:type=[inst:Map<dynamic,dynamic>]*/
testEmptyMapLiteral() => {};

/*element: testEmptyMapLiteralDynamic:type=[inst:Map<dynamic,dynamic>]*/
testEmptyMapLiteralDynamic() => <dynamic, dynamic>{};

/*element: testEmptyMapLiteralTyped:type=[inst:Map<String,int>]*/
testEmptyMapLiteralTyped() => <String, int>{};

/*strong.element: testEmptyMapLiteralConstant:
type=[
 inst:ConstantMap<dynamic,dynamic>,
 inst:ConstantProtoMap<dynamic,dynamic>,
 inst:ConstantStringMap<dynamic,dynamic>,
 inst:GeneralConstantMap<dynamic,dynamic>]*/
/*strongConst.element: testEmptyMapLiteralConstant:constant=[{}]*/
testEmptyMapLiteralConstant() => const {};

/*element: testNonEmptyMapLiteral:type=[inst:JSBool,inst:JSNull,inst:Map<Null,bool>]*/
testNonEmptyMapLiteral() => {null: true};

class GenericClass<X, Y> {
  /*strong.element: GenericClass.generative:static=[Object.(0)]*/
  const GenericClass.generative();
}
