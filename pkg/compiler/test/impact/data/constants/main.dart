// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart';
import 'lib.dart' deferred as defer;

/*member: main:static=%*/
main() {
  nullLiteral();
  boolLiteral();
  intLiteral();
  doubleLiteral();
  stringLiteral();
  symbolLiteral();
  listLiteral();
  mapLiteral();
  stringMapLiteral();
  setLiteral();
  instanceConstant();
  typeLiteral();
  instantiation();
  topLevelTearOff();
  staticTearOff();

  nullLiteralRef();
  boolLiteralRef();
  intLiteralRef();
  doubleLiteralRef();
  stringLiteralRef();
  symbolLiteralRef();
  listLiteralRef();
  mapLiteralRef();
  stringMapLiteralRef();
  setLiteralRef();
  instanceConstantRef();
  typeLiteralRef();
  instantiationRef();
  topLevelTearOffRef();
  staticTearOffRef();

  nullLiteralDeferred();
  boolLiteralDeferred();
  intLiteralDeferred();
  doubleLiteralDeferred();
  stringLiteralDeferred();
  symbolLiteralDeferred();
  listLiteralDeferred();
  mapLiteralDeferred();
  stringMapLiteralDeferred();
  setLiteralDeferred();
  instanceConstantDeferred();
  typeLiteralDeferred();
  instantiationDeferred();
  topLevelTearOffDeferred();
  staticTearOffDeferred();
}

/*member: nullLiteral:type=[inst:JSNull]*/
nullLiteral() {
  const dynamic local = null;
  return local;
}

/*member: boolLiteral:type=[inst:JSBool]*/
boolLiteral() {
  const dynamic local = true;
  return local;
}

/*member: intLiteral:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteral() {
  const dynamic local = 42;
  return local;
}

/*member: doubleLiteral:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteral() {
  const dynamic local = 0.5;
  return local;
}

/*member: stringLiteral:type=[inst:JSString]*/
stringLiteral() {
  const dynamic local = "foo";
  return local;
}

/*member: symbolLiteral:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteral() => #foo;

/*member: listLiteral:type=[
  inst:JSBool,
  inst:List<bool*>]*/
listLiteral() => const [true, false];

/*member: mapLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteral() => const {true: false};

/*member: stringMapLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteral() => const {'foo': false};

/*member: setLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteral() => const {true, false};

/*member: instanceConstant:
 static=[Class.field2=BoolConstant(false),SuperClass.field1=BoolConstant(true)],
 type=[const:Class,inst:JSBool]
*/
instanceConstant() => const Class(true, false);

/*member: typeLiteral:
 static=[
  createRuntimeType(1),
  typeLiteral(1)],
 type=[
  inst:Type,
  inst:_Type,
  lit:String*]
*/
typeLiteral() {
  const dynamic local = String;
  return local;
}

/*member: instantiation:static=[closureFunctionType(1),id,instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiation() {
  const int Function(int) local = id;
  return local;
}

/*member: topLevelTearOff:static=[topLevelMethod]*/
topLevelTearOff() {
  const dynamic local = topLevelMethod;
  return local;
}

/*member: staticTearOff:static=[Class.staticMethodField]*/
staticTearOff() {
  const dynamic local = Class.staticMethodField;
  return local;
}

/*member: nullLiteralRef:type=[inst:JSNull]*/
nullLiteralRef() => nullLiteralField;

/*member: boolLiteralRef:type=[inst:JSBool]*/
boolLiteralRef() => boolLiteralField;

/*member: intLiteralRef:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteralRef() => intLiteralField;

/*member: doubleLiteralRef:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteralRef() => doubleLiteralField;

/*member: stringLiteralRef:type=[inst:JSString]*/
stringLiteralRef() => stringLiteralField;

/*member: symbolLiteralRef:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteralRef() => symbolLiteralField;

/*member: listLiteralRef:type=[
  inst:JSBool,
  inst:List<bool*>]*/
listLiteralRef() => listLiteralField;

/*member: mapLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteralRef() => mapLiteralField;

/*member: stringMapLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteralRef() => stringMapLiteralField;

/*member: setLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteralRef() => setLiteralField;

/*member: instanceConstantRef:
 static=[Class.field2=BoolConstant(false),SuperClass.field1=BoolConstant(true)],
 type=[const:Class,inst:JSBool]
*/
instanceConstantRef() => instanceConstantField;

/*member: typeLiteralRef:
 static=[
  createRuntimeType(1),
  typeLiteral(1)],
 type=[
  inst:Type,
  inst:_Type,
  lit:String*]
*/
typeLiteralRef() => typeLiteralField;

/*member: instantiationRef:static=[closureFunctionType(1),id,instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiationRef() => instantiationField;

/*member: topLevelTearOffRef:static=[topLevelMethod]*/
topLevelTearOffRef() => topLevelTearOffField;

/*member: staticTearOffRef:static=[Class.staticMethodField]*/
staticTearOffRef() => staticTearOffField;

/*member: nullLiteralDeferred:type=[inst:JSNull]*/
nullLiteralDeferred() => defer.nullLiteralField;

/*member: boolLiteralDeferred:type=[inst:JSBool]*/
boolLiteralDeferred() => defer.boolLiteralField;

/*member: intLiteralDeferred:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteralDeferred() => defer.intLiteralField;

/*member: doubleLiteralDeferred:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteralDeferred() => defer.doubleLiteralField;

/*member: stringLiteralDeferred:type=[inst:JSString]*/
stringLiteralDeferred() => defer.stringLiteralField;

// TODO(johnniwinther): Should we record that this is deferred?
/*member: symbolLiteralDeferred:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteralDeferred() => defer.symbolLiteralField;

// TODO(johnniwinther): Should we record that this is deferred?
/*member: listLiteralDeferred:type=[
  inst:JSBool,
  inst:List<bool*>]*/
listLiteralDeferred() => defer.listLiteralField;

// TODO(johnniwinther): Should we record that this is deferred?
/*member: mapLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteralDeferred() => defer.mapLiteralField;

// TODO(johnniwinther): Should we record that this is deferred?
/*member: stringMapLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteralDeferred() => defer.stringMapLiteralField;

// TODO(johnniwinther): Should we record that this is deferred?
/*member: setLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteralDeferred() => defer.setLiteralField;

/*member: instanceConstantDeferred:
 static=[Class.field2=BoolConstant(false),SuperClass.field1=BoolConstant(true)],
 type=[const:Class{defer},inst:JSBool]
*/
instanceConstantDeferred() => defer.instanceConstantField;

/*member: typeLiteralDeferred:
 static=[
  createRuntimeType(1),
  typeLiteral(1)],
 type=[
  inst:Type,
  inst:_Type,
  lit:String*{defer}]
*/
typeLiteralDeferred() => defer.typeLiteralField;

/*member: instantiationDeferred:static=[closureFunctionType(1),id{defer},instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiationDeferred() => defer.instantiationField;

/*member: topLevelTearOffDeferred:static=[topLevelMethod{defer}]*/
topLevelTearOffDeferred() => defer.topLevelTearOffField;

/*member: staticTearOffDeferred:static=[Class.staticMethodField{defer}]*/
staticTearOffDeferred() => defer.staticTearOffField;
