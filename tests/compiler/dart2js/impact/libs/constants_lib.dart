// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.member: nullLiteralField:type=[inst:JSNull]*/
const dynamic nullLiteralField = null;

/*strong.member: boolLiteralField:type=[inst:JSBool]*/
const dynamic boolLiteralField = true;

/*strong.member: intLiteralField:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
const dynamic intLiteralField = 42;

/*strong.member: doubleLiteralField:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
const dynamic doubleLiteralField = 0.5;

/*strong.member: stringLiteralField:type=[inst:JSString]*/
const dynamic stringLiteralField = "foo";

/*strong.member: symbolLiteralField:static=[Symbol.(1)],type=[inst:Symbol]*/
const dynamic symbolLiteralField = #foo;

/*strong.member: listLiteralField:type=[inst:JSBool,inst:List<bool>]*/
const dynamic listLiteralField = [true, false];

/*strong.member: mapLiteralField:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
const dynamic mapLiteralField = {true: false};

/*strong.member: stringMapLiteralField:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
const dynamic stringMapLiteralField = {'foo': false};

/*strong.member: setLiteralField:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
const dynamic setLiteralField = {true, false};

class SuperClass {
  /*member: SuperClass.field1:type=[inst:JSNull]*/
  final field1;

  /*strong.member: SuperClass.:static=[Object.(0),init:SuperClass.field1]*/
  const SuperClass(this.field1);
}

class Class extends SuperClass {
  /*member: Class.field2:type=[inst:JSNull]*/
  final field2;

  /*strong.member: Class.:static=[SuperClass.(1),init:Class.field2]*/
  const Class(field1, this.field2) : super(field1);

  static staticMethodField() {}
}

/*strong.member: instanceConstantField:static=[Class.(2)],type=[inst:JSBool,param:Class]*/
const instanceConstantField = const Class(true, false);

/*strong.member: typeLiteralField:static=[createRuntimeType(1)],type=[inst:JSBool,inst:Type,inst:TypeImpl,lit:String,param:Type]*/
const typeLiteralField = String;

/*member: id:static=[checkSubtype(4),checkSubtypeOfRuntimeType(2),getRuntimeTypeArgument(3),getRuntimeTypeArgumentIntercepted(4),getRuntimeTypeInfo(1),getTypeArgumentByIndex(2),setRuntimeTypeInfo(2)],type=[inst:JSArray<dynamic>,inst:JSBool,inst:JSExtendableArray<dynamic>,inst:JSFixedArray<dynamic>,inst:JSMutableArray<dynamic>,inst:JSUnmodifiableArray<dynamic>,param:Object,param:id.T]*/
T id<T>(T t) => t;

/*strong.member: _instantiation:
 static=[
  checkSubtype(4),
  extractFunctionTypeObjectFromInternal(1),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  id,instantiate1(1),
  instantiatedGenericFunctionType(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:Instantiation1<dynamic>,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:int Function(int)]
*/
const int Function(int) _instantiation = id;

/*strong.member: instantiationField:static=[_instantiation]*/
const dynamic instantiationField = _instantiation;

topLevelMethod() {}

/*strong.member: topLevelTearOffField:static=[topLevelMethod]*/
const dynamic topLevelTearOffField = topLevelMethod;

/*strong.member: staticTearOffField:static=[Class.staticMethodField]*/
const dynamic staticTearOffField = Class.staticMethodField;
