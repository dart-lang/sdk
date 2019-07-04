// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/constants_lib.dart';
import '../libs/constants_lib.dart' deferred as defer;

/*member: main:static=**/
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

/*member: listLiteral:type=[inst:JSBool,inst:List<bool>]*/
listLiteral() => const [true, false];

/*member: mapLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteral() => const {true: false};

/*member: stringMapLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteral() => const {'foo': false};

/*member: setLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteral() => const {true, false};

/*strong.member: instanceConstant:static=[Class.(2)],type=[inst:JSBool]*/
/*strongConst.member: instanceConstant:
 static=[Class.field2=BoolConstant(false),SuperClass.field1=BoolConstant(true)],
 type=[const:Class,inst:JSBool]
*/
instanceConstant() => const Class(true, false);

/*member: typeLiteral:static=[createRuntimeType(1)],type=[inst:Type,inst:TypeImpl,lit:String]*/
typeLiteral() {
  const dynamic local = String;
  return local;
}

/*member: instantiation:static=[extractFunctionTypeObjectFromInternal(1),id,instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
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

/*strong.member: nullLiteralRef:static=[nullLiteralField]*/
/*strongConst.member: nullLiteralRef:type=[inst:JSNull]*/
nullLiteralRef() => nullLiteralField;

/*strong.member: boolLiteralRef:static=[boolLiteralField]*/
/*strongConst.member: boolLiteralRef:type=[inst:JSBool]*/
boolLiteralRef() => boolLiteralField;

/*strong.member: intLiteralRef:static=[intLiteralField]*/
/*strongConst.member: intLiteralRef:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteralRef() => intLiteralField;

/*strong.member: doubleLiteralRef:static=[doubleLiteralField]*/
/*strongConst.member: doubleLiteralRef:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteralRef() => doubleLiteralField;

/*strong.member: stringLiteralRef:static=[stringLiteralField]*/
/*strongConst.member: stringLiteralRef:type=[inst:JSString]*/
stringLiteralRef() => stringLiteralField;

/*strong.member: symbolLiteralRef:static=[symbolLiteralField]*/
/*strongConst.member: symbolLiteralRef:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteralRef() => symbolLiteralField;

/*strong.member: listLiteralRef:static=[listLiteralField]*/
/*strongConst.member: listLiteralRef:type=[inst:JSBool,inst:List<bool>]*/
listLiteralRef() => listLiteralField;

/*strong.member: mapLiteralRef:static=[mapLiteralField]*/
/*strongConst.member: mapLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteralRef() => mapLiteralField;

/*strong.member: stringMapLiteralRef:static=[stringMapLiteralField]*/
/*strongConst.member: stringMapLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteralRef() => stringMapLiteralField;

/*strong.member: setLiteralRef:static=[setLiteralField]*/
/*strongConst.member: setLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteralRef() => setLiteralField;

/*strong.member: instanceConstantRef:static=[instanceConstantField]*/
/*strongConst.member: instanceConstantRef:
 static=[Class.field2=BoolConstant(false),SuperClass.field1=BoolConstant(true)],
 type=[const:Class,inst:JSBool]
*/
instanceConstantRef() => instanceConstantField;

/*strong.member: typeLiteralRef:static=[typeLiteralField]*/
/*strongConst.member: typeLiteralRef:static=[createRuntimeType(1)],type=[inst:Type,inst:TypeImpl,lit:String]*/
typeLiteralRef() => typeLiteralField;

/*strong.member: instantiationRef:static=[instantiationField]*/
/*strongConst.member: instantiationRef:static=[extractFunctionTypeObjectFromInternal(1),id,instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiationRef() => instantiationField;

/*strong.member: topLevelTearOffRef:static=[topLevelTearOffField]*/
/*strongConst.member: topLevelTearOffRef:static=[topLevelMethod]*/
topLevelTearOffRef() => topLevelTearOffField;

/*strong.member: staticTearOffRef:static=[staticTearOffField]*/
/*strongConst.member: staticTearOffRef:static=[Class.staticMethodField]*/
staticTearOffRef() => staticTearOffField;

/*strong.member: nullLiteralDeferred:static=[nullLiteralField{defer}]*/
/*strongConst.member: nullLiteralDeferred:type=[inst:JSNull]*/
nullLiteralDeferred() => defer.nullLiteralField;

/*strong.member: boolLiteralDeferred:static=[boolLiteralField{defer}]*/
/*strongConst.member: boolLiteralDeferred:type=[inst:JSBool]*/
boolLiteralDeferred() => defer.boolLiteralField;

/*strong.member: intLiteralDeferred:static=[intLiteralField{defer}]*/
/*strongConst.member: intLiteralDeferred:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteralDeferred() => defer.intLiteralField;

/*strong.member: doubleLiteralDeferred:static=[doubleLiteralField{defer}]*/
/*strongConst.member: doubleLiteralDeferred:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteralDeferred() => defer.doubleLiteralField;

/*strong.member: stringLiteralDeferred:static=[stringLiteralField{defer}]*/
/*strongConst.member: stringLiteralDeferred:type=[inst:JSString]*/
stringLiteralDeferred() => defer.stringLiteralField;

/*strong.member: symbolLiteralDeferred:static=[symbolLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.member: symbolLiteralDeferred:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteralDeferred() => defer.symbolLiteralField;

/*strong.member: listLiteralDeferred:static=[listLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.member: listLiteralDeferred:type=[inst:JSBool,inst:List<bool>]*/
listLiteralDeferred() => defer.listLiteralField;

/*strong.member: mapLiteralDeferred:static=[mapLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.member: mapLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteralDeferred() => defer.mapLiteralField;

/*strong.member: stringMapLiteralDeferred:static=[stringMapLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.member: stringMapLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteralDeferred() => defer.stringMapLiteralField;

/*strong.member: setLiteralDeferred:static=[setLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.member: setLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteralDeferred() => defer.setLiteralField;

/*strong.member: instanceConstantDeferred:static=[instanceConstantField{defer}]*/
/*strongConst.member: instanceConstantDeferred:
 static=[Class.field2=BoolConstant(false),SuperClass.field1=BoolConstant(true)],
 type=[const:Class{defer},inst:JSBool]
*/
instanceConstantDeferred() => defer.instanceConstantField;

/*strong.member: typeLiteralDeferred:static=[typeLiteralField{defer}]*/
/*strongConst.member: typeLiteralDeferred:static=[createRuntimeType(1)],type=[inst:Type,inst:TypeImpl,lit:String{defer}]*/
typeLiteralDeferred() => defer.typeLiteralField;

/*strong.member: instantiationDeferred:static=[instantiationField{defer}]*/
/*strongConst.member: instantiationDeferred:static=[extractFunctionTypeObjectFromInternal(1),id{defer},instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiationDeferred() => defer.instantiationField;

/*strong.member: topLevelTearOffDeferred:static=[topLevelTearOffField{defer}]*/
/*strongConst.member: topLevelTearOffDeferred:static=[topLevelMethod{defer}]*/
topLevelTearOffDeferred() => defer.topLevelTearOffField;

/*strong.member: staticTearOffDeferred:static=[staticTearOffField{defer}]*/
/*strongConst.member: staticTearOffDeferred:static=[Class.staticMethodField{defer}]*/
staticTearOffDeferred() => defer.staticTearOffField;
