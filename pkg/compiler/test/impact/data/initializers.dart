// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:
 static=[
  testDefaultValuesNamed(0),
  testDefaultValuesPositional(0),
  testFieldInitializer1(0),
  testFieldInitializer2(0),
  testFieldInitializer3(0),
  testGenericClass(0),
  testInstanceFieldTyped(0),
  testInstanceFieldWithInitializer(0),
  testSuperInitializer(0),
  testThisInitializer(0)]
*/
main() {
  testDefaultValuesPositional();
  testDefaultValuesNamed();
  testFieldInitializer1();
  testFieldInitializer2();
  testFieldInitializer3();
  testInstanceFieldWithInitializer();
  testInstanceFieldTyped();
  testThisInitializer();
  testSuperInitializer();
  testGenericClass();
}

/*member: testDefaultValuesPositional:
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
  instanceType(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  param:bool*]
*/
testDefaultValuesPositional([bool value = false]) {}

/*member: testDefaultValuesNamed:
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
  instanceType(1)],
 type=[
  inst:Closure,
  inst:JSBool,
  param:bool*]
*/
testDefaultValuesNamed({bool value: false}) {}

class ClassFieldInitializer1 {
  /*member: ClassFieldInitializer1.field:type=[inst:JSNull]*/
  var field;

  /*member: ClassFieldInitializer1.:static=[Object.(0),init:ClassFieldInitializer1.field]*/
  ClassFieldInitializer1(this.field);
}

/*member: testFieldInitializer1:
 static=[ClassFieldInitializer1.(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testFieldInitializer1() => new ClassFieldInitializer1(42);

class ClassFieldInitializer2 {
  /*member: ClassFieldInitializer2.field:type=[inst:JSNull]*/
  var field;

  /*member: ClassFieldInitializer2.:static=[Object.(0),init:ClassFieldInitializer2.field]*/
  ClassFieldInitializer2(value) : field = value;
}

/*member: testFieldInitializer2:
 static=[ClassFieldInitializer2.(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testFieldInitializer2() => new ClassFieldInitializer2(42);

class ClassFieldInitializer3 {
  /*member: ClassFieldInitializer3.field:type=[inst:JSNull]*/
  var field;

  /*member: ClassFieldInitializer3.a:static=[Object.(0),init:ClassFieldInitializer3.field],type=[inst:JSNull]*/
  ClassFieldInitializer3.a();

  /*member: ClassFieldInitializer3.b:static=[Object.(0),init:ClassFieldInitializer3.field]*/
  ClassFieldInitializer3.b(value) : field = value;
}

/*member: testFieldInitializer3:
 static=[ClassFieldInitializer3.a(0),ClassFieldInitializer3.b(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testFieldInitializer3() {
  new ClassFieldInitializer3.a();
  new ClassFieldInitializer3.b(42);
}

/*member: ClassInstanceFieldWithInitializer.:static=[Object.(0)]*/
class ClassInstanceFieldWithInitializer {
  /*member: ClassInstanceFieldWithInitializer.field:
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
    instanceType(1)],
   type=[
    inst:Closure,
    inst:JSBool,
    param:bool*]
  */
  var field = false;
}

/*member: testInstanceFieldWithInitializer:static=[ClassInstanceFieldWithInitializer.(0)]*/
testInstanceFieldWithInitializer() => new ClassInstanceFieldWithInitializer();

/*member: ClassInstanceFieldTyped.:static=[Object.(0)]*/
class ClassInstanceFieldTyped {
  /*member: ClassInstanceFieldTyped.field:
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
    instanceType(1)],
   type=[
    inst:Closure,
    inst:JSBool,
    inst:JSNull,
    param:int*]
  */
  int field;
}

/*member: testInstanceFieldTyped:static=[ClassInstanceFieldTyped.(0)]*/
testInstanceFieldTyped() => new ClassInstanceFieldTyped();

class ClassThisInitializer {
  /*member: ClassThisInitializer.:static=[ClassThisInitializer.internal(0)]*/
  ClassThisInitializer() : this.internal();

  /*member: ClassThisInitializer.internal:static=[Object.(0)]*/
  ClassThisInitializer.internal();
}

/*member: testThisInitializer:static=[ClassThisInitializer.(0)]*/
testThisInitializer() => new ClassThisInitializer();

class ClassSuperInitializer extends ClassThisInitializer {
  /*member: ClassSuperInitializer.:static=[ClassThisInitializer.internal(0)]*/
  ClassSuperInitializer() : super.internal();
}

/*member: testSuperInitializer:static=[ClassSuperInitializer.(0)]*/
testSuperInitializer() => new ClassSuperInitializer();

class ClassGeneric<T> {
  /*member: ClassGeneric.:
   static=[
    Object.(0),
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
    setRuntimeTypeInfo(2)],
   type=[
    inst:Closure,
    inst:JSArray<dynamic>,
    inst:JSBool,
    inst:JSExtendableArray<dynamic>,
    inst:JSFixedArray<dynamic>,
    inst:JSMutableArray<dynamic>,
    inst:JSUnmodifiableArray<dynamic>,
    param:ClassGeneric.T*]
  */
  ClassGeneric(T arg);
}

/*member: testGenericClass:
 static=[
  ClassGeneric.(1),
  checkTypeBound(4)],
 type=[
  inst:JSDouble,
  inst:JSInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
testGenericClass() => new ClassGeneric<int>(0);
