// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/constants_lib.dart';
import '../libs/constants_lib.dart' deferred as defer;

/*element: main:static=**/
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

/*element: nullLiteral:type=[inst:JSNull]*/
nullLiteral() {
  const dynamic local = null;
  return local;
}

/*element: boolLiteral:type=[inst:JSBool]*/
boolLiteral() {
  const dynamic local = true;
  return local;
}

/*element: intLiteral:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteral() {
  const dynamic local = 42;
  return local;
}

/*element: doubleLiteral:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteral() {
  const dynamic local = 0.5;
  return local;
}

/*element: stringLiteral:type=[inst:JSString]*/
stringLiteral() {
  const dynamic local = "foo";
  return local;
}

/*element: symbolLiteral:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteral() => #foo;

/*element: listLiteral:type=[inst:JSBool,inst:List<bool>]*/
listLiteral() => const [true, false];

/*element: mapLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteral() => const {true: false};

/*element: stringMapLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteral() => const {'foo': false};

/*element: setLiteral:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteral() => const {true, false};

/*strong.element: instanceConstant:static=[Class.(2)],type=[inst:JSBool]*/
/*strongConst.element: instanceConstant:static=[init:Class.field2,init:SuperClass.field1],type=[const:Class,inst:JSBool]*/
instanceConstant() => const Class(true, false);

/*element: typeLiteral:static=[createRuntimeType(1)],type=[inst:Type,inst:TypeImpl,lit:String]*/
typeLiteral() {
  const dynamic local = String;
  return local;
}

/*element: instantiation:static=[extractFunctionTypeObjectFromInternal(1),id,instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiation() {
  const int Function(int) local = id;
  return local;
}

/*element: topLevelTearOff:static=[topLevelMethod]*/
topLevelTearOff() {
  const dynamic local = topLevelMethod;
  return local;
}

/*element: staticTearOff:static=[Class.staticMethodField]*/
staticTearOff() {
  const dynamic local = Class.staticMethodField;
  return local;
}

/*strong.element: nullLiteralRef:static=[nullLiteralField]*/
/*strongConst.element: nullLiteralRef:type=[inst:JSNull]*/
nullLiteralRef() => nullLiteralField;

/*strong.element: boolLiteralRef:static=[boolLiteralField]*/
/*strongConst.element: boolLiteralRef:type=[inst:JSBool]*/
boolLiteralRef() => boolLiteralField;

/*strong.element: intLiteralRef:static=[intLiteralField]*/
/*strongConst.element: intLiteralRef:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteralRef() => intLiteralField;

/*strong.element: doubleLiteralRef:static=[doubleLiteralField]*/
/*strongConst.element: doubleLiteralRef:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteralRef() => doubleLiteralField;

/*strong.element: stringLiteralRef:static=[stringLiteralField]*/
/*strongConst.element: stringLiteralRef:type=[inst:JSString]*/
stringLiteralRef() => stringLiteralField;

/*strong.element: symbolLiteralRef:static=[symbolLiteralField]*/
/*strongConst.element: symbolLiteralRef:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteralRef() => symbolLiteralField;

/*strong.element: listLiteralRef:static=[listLiteralField]*/
/*strongConst.element: listLiteralRef:type=[inst:JSBool,inst:List<bool>]*/
listLiteralRef() => listLiteralField;

/*strong.element: mapLiteralRef:static=[mapLiteralField]*/
/*strongConst.element: mapLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteralRef() => mapLiteralField;

/*strong.element: stringMapLiteralRef:static=[stringMapLiteralField]*/
/*strongConst.element: stringMapLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteralRef() => stringMapLiteralField;

/*strong.element: setLiteralRef:static=[setLiteralField]*/
/*strongConst.element: setLiteralRef:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteralRef() => setLiteralField;

/*strong.element: instanceConstantRef:static=[instanceConstantField]*/
/*strongConst.element: instanceConstantRef:static=[init:Class.field2,init:SuperClass.field1],type=[const:Class,inst:JSBool]*/
instanceConstantRef() => instanceConstantField;

/*strong.element: typeLiteralRef:static=[typeLiteralField]*/
/*strongConst.element: typeLiteralRef:static=[createRuntimeType(1)],type=[inst:Type,inst:TypeImpl,lit:String]*/
typeLiteralRef() => typeLiteralField;

/*strong.element: instantiationRef:static=[instantiationField]*/
/*strongConst.element: instantiationRef:static=[extractFunctionTypeObjectFromInternal(1),id,instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiationRef() => instantiationField;

/*strong.element: topLevelTearOffRef:static=[topLevelTearOffField]*/
/*strongConst.element: topLevelTearOffRef:static=[topLevelMethod]*/
topLevelTearOffRef() => topLevelTearOffField;

/*strong.element: staticTearOffRef:static=[staticTearOffField]*/
/*strongConst.element: staticTearOffRef:static=[Class.staticMethodField]*/
staticTearOffRef() => staticTearOffField;

/*strong.element: nullLiteralDeferred:static=[nullLiteralField{defer}]*/
/*strongConst.element: nullLiteralDeferred:type=[inst:JSNull]*/
nullLiteralDeferred() => defer.nullLiteralField;

/*strong.element: boolLiteralDeferred:static=[boolLiteralField{defer}]*/
/*strongConst.element: boolLiteralDeferred:type=[inst:JSBool]*/
boolLiteralDeferred() => defer.boolLiteralField;

/*strong.element: intLiteralDeferred:static=[intLiteralField{defer}]*/
/*strongConst.element: intLiteralDeferred:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
intLiteralDeferred() => defer.intLiteralField;

/*strong.element: doubleLiteralDeferred:static=[doubleLiteralField{defer}]*/
/*strongConst.element: doubleLiteralDeferred:type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
doubleLiteralDeferred() => defer.doubleLiteralField;

/*strong.element: stringLiteralDeferred:static=[stringLiteralField{defer}]*/
/*strongConst.element: stringLiteralDeferred:type=[inst:JSString]*/
stringLiteralDeferred() => defer.stringLiteralField;

/*strong.element: symbolLiteralDeferred:static=[symbolLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.element: symbolLiteralDeferred:static=[Symbol.(1)],type=[inst:Symbol]*/
symbolLiteralDeferred() => defer.symbolLiteralField;

/*strong.element: listLiteralDeferred:static=[listLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.element: listLiteralDeferred:type=[inst:JSBool,inst:List<bool>]*/
listLiteralDeferred() => defer.listLiteralField;

/*strong.element: mapLiteralDeferred:static=[mapLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.element: mapLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool]*/
mapLiteralDeferred() => defer.mapLiteralField;

/*strong.element: stringMapLiteralDeferred:static=[stringMapLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.element: stringMapLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:JSString]*/
stringMapLiteralDeferred() => defer.stringMapLiteralField;

/*strong.element: setLiteralDeferred:static=[setLiteralField{defer}]*/
// TODO(johnniwinther): Should we record that this is deferred?
/*strongConst.element: setLiteralDeferred:type=[inst:ConstantMap<dynamic,dynamic>,inst:ConstantProtoMap<dynamic,dynamic>,inst:ConstantStringMap<dynamic,dynamic>,inst:GeneralConstantMap<dynamic,dynamic>,inst:JSBool,inst:_UnmodifiableSet<dynamic>]*/
setLiteralDeferred() => defer.setLiteralField;

/*strong.element: instanceConstantDeferred:static=[instanceConstantField{defer}]*/
/*strongConst.element: instanceConstantDeferred:static=[init:Class.field2,init:SuperClass.field1],type=[const:Class{defer},inst:JSBool]*/
instanceConstantDeferred() => defer.instanceConstantField;

/*strong.element: typeLiteralDeferred:static=[typeLiteralField{defer}]*/
/*strongConst.element: typeLiteralDeferred:static=[createRuntimeType(1)],type=[inst:Type,inst:TypeImpl,lit:String{defer}]*/
typeLiteralDeferred() => defer.typeLiteralField;

/*strong.element: instantiationDeferred:static=[instantiationField{defer}]*/
/*strongConst.element: instantiationDeferred:static=[extractFunctionTypeObjectFromInternal(1),id{defer},instantiate1(1),instantiatedGenericFunctionType(2)],type=[inst:Instantiation1<dynamic>]*/
instantiationDeferred() => defer.instantiationField;

/*strong.element: topLevelTearOffDeferred:static=[topLevelTearOffField{defer}]*/
/*strongConst.element: topLevelTearOffDeferred:static=[topLevelMethod{defer}]*/
topLevelTearOffDeferred() => defer.topLevelTearOffField;

/*strong.element: staticTearOffDeferred:static=[staticTearOffField{defer}]*/
/*strongConst.element: staticTearOffDeferred:static=[Class.staticMethodField{defer}]*/
staticTearOffDeferred() => defer.staticTearOffField;
