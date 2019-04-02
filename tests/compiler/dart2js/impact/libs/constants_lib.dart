// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.element: nullLiteralField:type=[inst:JSNull]*/
const dynamic nullLiteralField = null;

/*strong.element: boolLiteralField:type=[inst:JSBool]*/
const dynamic boolLiteralField = true;

/*strong.element: intLiteralField:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
const dynamic intLiteralField = 42;

/*strong.element: doubleLiteralField:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
const dynamic doubleLiteralField = 0.5;

/*strong.element: stringLiteralField:type=[inst:JSString]*/
const dynamic stringLiteralField = "foo";

/*strong.element: symbolLiteralField:static=[Symbol.(1)],type=[inst:Symbol]*/
const dynamic symbolLiteralField = #foo;

/*strong.element: listLiteralField:type=[inst:JSBool,inst:List<bool>]*/
const dynamic listLiteralField = [true, false];

/*strong.element: mapLiteralField:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
const dynamic mapLiteralField = {true: false};

/*strong.element: stringMapLiteralField:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
const dynamic stringMapLiteralField = {'foo': false};

/*strong.element: setLiteralField:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
const dynamic setLiteralField = {true, false};

class SuperClass {
  /*element: SuperClass.field1:type=[inst:JSNull]*/
  final field1;

  /*strong.element: SuperClass.:static=[Object.(0),init:SuperClass.field1]*/
  const SuperClass(this.field1);
}

class Class extends SuperClass {
  /*element: Class.field2:type=[inst:JSNull]*/
  final field2;

  /*strong.element: Class.:static=[SuperClass.(1),init:Class.field2]*/
  const Class(field1, this.field2) : super(field1);

  static staticMethodField() {}
}

/*strong.element: instanceConstantField:static=[Class.(2)],type=[inst:JSBool,param:Class]*/
const instanceConstantField = const Class(true, false);

/*strong.element: typeLiteralField:static=[createRuntimeType(1)],type=[inst:JSBool,inst:Type,inst:TypeImpl,lit:String,param:Type]*/
const typeLiteralField = String;

/*element: id:static=[checkSubtype(4),checkSubtypeOfRuntimeType(2),getRuntimeTypeArgument(3),getRuntimeTypeArgumentIntercepted(4),getRuntimeTypeInfo(1),getTypeArgumentByIndex(2),setRuntimeTypeInfo(2)],type=[inst:JSArray<dynamic>,inst:JSBool,inst:JSExtendableArray<dynamic>,inst:JSFixedArray<dynamic>,inst:JSMutableArray<dynamic>,inst:JSUnmodifiableArray<dynamic>,param:Object,param:id.T]*/
T id<T>(T t) => t;

/*strong.element: _instantiation:
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

/*strong.element: instantiationField:static=[_instantiation]*/
const dynamic instantiationField = _instantiation;

topLevelMethod() {}

/*strong.element: topLevelTearOffField:static=[topLevelMethod]*/
const dynamic topLevelTearOffField = topLevelMethod;

/*strong.element: staticTearOffField:static=[Class.staticMethodField]*/
const dynamic staticTearOffField = Class.staticMethodField;
