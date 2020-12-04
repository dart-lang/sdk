// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:static=[
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

/*member: testEmpty:*/
testEmpty() {}

/*member: testNull:type=[inst:JSNull]*/
testNull() => null;

/*member: testTrue:type=[inst:JSBool]*/
testTrue() => true;

/*member: testFalse:type=[inst:JSBool]*/
testFalse() => false;

/*member: testInt:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
testInt() => 42;

/*member: testDouble:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
testDouble() => 37.5;

/*member: testString:type=[inst:JSString]*/
testString() => 'foo';

/*member: testStringInterpolation:type=[inst:JSString]*/
testStringInterpolation() => '${true}';

/*member: testStringInterpolationConst:type=[inst:JSString]*/
testStringInterpolationConst() {
  const b = '${true}';
  return b;
}

/*member: testStringJuxtaposition:type=[inst:JSString]*/
testStringJuxtaposition() => 'a' 'b';

/*member: testSymbol:static=[Symbol.(1)],type=[inst:Symbol]*/
testSymbol() => #main;

/*member: testConstSymbol:static=[Symbol.(1)],type=[inst:Symbol]*/
testConstSymbol() => const Symbol('main');

const complexSymbolField1 = "true".length == 4;

const complexSymbolField2 = "true" "false" "${true}${null}";

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

const complexSymbolField =
    complexSymbolField1 ? complexSymbolField2 : complexSymbolField3;

/*member: testComplexConstSymbol:static=[Symbol.(1)],type=[inst:Symbol]*/
testComplexConstSymbol() => const Symbol(complexSymbolField);

/*member: testIfNullConstSymbol:static=[Symbol.(1)],type=[inst:Symbol]*/
testIfNullConstSymbol() => const Symbol(null ?? 'foo');

/*member: testTypeLiteral:
 static=[
  createRuntimeType(1),
  typeLiteral(1)],
 type=[
  inst:Type,
  inst:_Type,
  lit:Object*]
*/
testTypeLiteral() => Object;

/*member: testBoolFromEnvironment:type=[inst:JSBool]*/
testBoolFromEnvironment() => const bool.fromEnvironment('FOO');

/*member: testEmptyListLiteral:type=[inst:List<dynamic>]*/
testEmptyListLiteral() => [];

/*member: testEmptyListLiteralDynamic:type=[inst:List<dynamic>]*/
testEmptyListLiteralDynamic() => <dynamic>[];

/*member: testEmptyListLiteralTyped:type=[inst:List<String*>]*/
testEmptyListLiteralTyped() => <String>[];

/*member: testEmptyListLiteralConstant:type=[inst:List<dynamic>]*/
testEmptyListLiteralConstant() => const [];

/*member: testNonEmptyListLiteral:type=[
  inst:JSBool,
  inst:List<bool*>]*/
testNonEmptyListLiteral() => [true];

/*member: testEmptyMapLiteral:type=[inst:Map<dynamic,dynamic>]*/
testEmptyMapLiteral() => {};

/*member: testEmptyMapLiteralDynamic:type=[inst:Map<dynamic,dynamic>]*/
testEmptyMapLiteralDynamic() => <dynamic, dynamic>{};

/*member: testEmptyMapLiteralTyped:type=[inst:Map<String*,int*>]*/
testEmptyMapLiteralTyped() => <String, int>{};

/*member: testEmptyMapLiteralConstant:
type=[
 inst:ConstantMap<dynamic,dynamic>,
 inst:ConstantProtoMap<dynamic,dynamic>,
 inst:ConstantStringMap<dynamic,dynamic>,
 inst:GeneralConstantMap<dynamic,dynamic>]
*/
testEmptyMapLiteralConstant() => const {};

/*member: testNonEmptyMapLiteral:type=[
  inst:JSBool,
  inst:JSNull,
  inst:Map<Null,bool*>]*/
testNonEmptyMapLiteral() => {null: true};

class GenericClass<X, Y> {
  const GenericClass.generative();
}
