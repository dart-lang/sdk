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

/*element: testStringInterpolation:dynamic=[toString(0)],static=[S],type=[inst:JSBool,inst:JSString]*/
testStringInterpolation() => '${true}';

/*element: testStringInterpolationConst:dynamic=[toString(0)],static=[S],type=[inst:JSBool,inst:JSString]*/
testStringInterpolationConst() {
  const b = '${true}';
  return b;
}

/*element: testStringJuxtaposition:dynamic=[toString(0)],static=[S],type=[inst:JSString]*/
testStringJuxtaposition() => 'a' 'b';

/*element: testSymbol:static=[Symbol.],type=[inst:Symbol]*/
testSymbol() => #main;

/*element: testConstSymbol:static=[Symbol.,Symbol.(1),Symbol.validated],type=[inst:JSString,inst:Symbol]*/
testConstSymbol() => const Symbol('main');

/*kernel.element: complexSymbolField1:
 dynamic=[==,length],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSString,inst:JSUInt31,inst:JSUInt32]
*/
/*strong.element: complexSymbolField1:
 dynamic=[==,length],
 type=[inst:JSBool,inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSString,inst:JSUInt31,inst:JSUInt32,param:bool]
*/
const complexSymbolField1 = "true".length == 4;

/*kernel.element: complexSymbolField2:dynamic=[toString(0)],static=[S],type=[inst:JSBool,inst:JSNull,inst:JSString]*/
/*strong.element: complexSymbolField2:dynamic=[toString(0)],static=[S],type=[inst:JSBool,inst:JSNull,inst:JSString,param:String]*/
const complexSymbolField2 = "true" "false" "${true}${null}";

/*kernel.element: complexSymbolField3:
dynamic=[+,unary-],
static=[
 GenericClass.generative(0),
 String.fromEnvironment(1),
 Symbol.,assertIsSubtype,
 bool.fromEnvironment(1,defaultValue),
 identical(2),
 int.fromEnvironment(1,defaultValue),
 override,
 testComplexConstSymbol,
 throwTypeError],
type=[
 check:int,
 inst:ConstantMap<dynamic,dynamic>,
 inst:ConstantProtoMap<dynamic,dynamic>,
 inst:ConstantStringMap<dynamic,dynamic>,
 inst:GeneralConstantMap<dynamic,dynamic>,
 inst:JSBool,
 inst:JSDouble,
 inst:JSInt,
 inst:JSNumber,
 inst:JSPositiveInt,
 inst:JSString,
 inst:JSUInt31,
 inst:JSUInt32,
 inst:List<int>,
 inst:Symbol]
*/
/*strong.element: complexSymbolField3:dynamic=[+,unary-],static=[GenericClass.generative(0),String.fromEnvironment(1),Symbol.,assertIsSubtype,bool.fromEnvironment(1,defaultValue),checkSubtype,getRuntimeTypeArgument,getRuntimeTypeArgumentIntercepted,getRuntimeTypeInfo,getTypeArgumentByIndex,identical(2),int.fromEnvironment(1,defaultValue),override,setRuntimeTypeInfo,testComplexConstSymbol,throwTypeError],type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSArray<dynamic>,inst:JSBool,inst:JSDouble,inst:JSExtendableArray<dynamic>,inst:JSFixedArray<dynamic>,inst:JSInt,inst:JSMutableArray<dynamic>,inst:JSNumber,inst:JSPositiveInt,inst:JSString,inst:JSUInt31,inst:JSUInt32,inst:JSUnmodifiableArray<dynamic>,inst:List<int>,inst:Symbol,param:Map<Object,Object>]*/
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

/*kernel.element: complexSymbolField:static=[complexSymbolField1,complexSymbolField2,complexSymbolField3]*/
/*strong.element: complexSymbolField:static=[complexSymbolField1,complexSymbolField2,complexSymbolField3],type=[inst:JSBool,param:Object]*/
const complexSymbolField =
    complexSymbolField1 ? complexSymbolField2 : complexSymbolField3;

/*kernel.element: testComplexConstSymbol:static=[Symbol.,Symbol.(1),Symbol.validated,complexSymbolField],type=[inst:Symbol]*/
/*strong.element: testComplexConstSymbol:static=[Symbol.,Symbol.(1),Symbol.validated,complexSymbolField],type=[impl:String,inst:JSBool,inst:Symbol]*/
testComplexConstSymbol() => const Symbol(complexSymbolField);

/*element: testIfNullConstSymbol:dynamic=[==],static=[Symbol.,Symbol.(1),Symbol.validated],type=[inst:JSNull,inst:JSString,inst:Symbol]*/
testIfNullConstSymbol() => const Symbol(null ?? 'foo');

/*element: testTypeLiteral:static=[createRuntimeType],type=[inst:Type,inst:TypeImpl,lit:Object]*/
testTypeLiteral() => Object;

/*element: testBoolFromEnvironment:static=[bool.fromEnvironment(1)],type=[inst:JSString]*/
testBoolFromEnvironment() => const bool.fromEnvironment('FOO');

/*element: testEmptyListLiteral:type=[inst:List<dynamic>]*/
testEmptyListLiteral() => [];

/*element: testEmptyListLiteralDynamic:type=[inst:List<dynamic>]*/
testEmptyListLiteralDynamic() => <dynamic>[];

/*kernel.element: testEmptyListLiteralTyped:type=[check:String,inst:List<String>]*/
/*strong.element: testEmptyListLiteralTyped:type=[inst:List<String>]*/
testEmptyListLiteralTyped() => <String>[];

/*element: testEmptyListLiteralConstant:type=[inst:List<dynamic>]*/
testEmptyListLiteralConstant() => const [];

/*kernel.element: testNonEmptyListLiteral:type=[inst:JSBool,inst:List<dynamic>]*/
/*strong.element: testNonEmptyListLiteral:type=[inst:JSBool,inst:List<bool>]*/
testNonEmptyListLiteral() => [true];

/*element: testEmptyMapLiteral:type=[inst:Map<dynamic,dynamic>]*/
testEmptyMapLiteral() => {};

/*element: testEmptyMapLiteralDynamic:type=[inst:Map<dynamic,dynamic>]*/
testEmptyMapLiteralDynamic() => <dynamic, dynamic>{};

/*kernel.element: testEmptyMapLiteralTyped:type=[check:String,check:int,inst:Map<String,int>]*/
/*strong.element: testEmptyMapLiteralTyped:type=[inst:Map<String,int>]*/
testEmptyMapLiteralTyped() => <String, int>{};

/*element: testEmptyMapLiteralConstant:
type=[
 inst:ConstantMap<dynamic,dynamic>,
 inst:ConstantProtoMap<dynamic,dynamic>,
 inst:ConstantStringMap<dynamic,dynamic>,
 inst:GeneralConstantMap<dynamic,dynamic>]*/
testEmptyMapLiteralConstant() => const {};

/*kernel.element: testNonEmptyMapLiteral:type=[inst:JSBool,inst:JSNull,inst:Map<dynamic,dynamic>]*/
/*strong.element: testNonEmptyMapLiteral:type=[inst:JSBool,inst:JSNull,inst:Map<Null,bool>]*/
testNonEmptyMapLiteral() => {null: true};

class GenericClass<X, Y> {
  /*element: GenericClass.generative:static=[Object.(0)]*/
  const GenericClass.generative();
}
