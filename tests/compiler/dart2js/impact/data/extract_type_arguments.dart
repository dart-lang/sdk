// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_internal';

class A<T> {}

class B<S, U> {}

/*member: C.:static=[Object.(0)]*/
class C implements A<int>, B<String, bool> {}

/*member: testA:dynamic=[call<A.T>(0)],static=[Rti._bind(1),Rti._eval(1),_arrayInstanceType(1),_asBoolNullable(1),_asDoubleNullable(1),_asIntNullable(1),_asNumNullable(1),_asObject(1),_asStringNullable(1),_asTop(1),_generalAsCheckImplementation(1),_generalIsTestImplementation(1),_installSpecializedIsTest(1),_instanceType(1),_isBool(1),_isInt(1),_isNum(1),_isObject(1),_isString(1),_isTop(1),checkSubtype(4),extractTypeArguments<A<dynamic>>(2),findType(1),getRuntimeTypeArgument(3),getRuntimeTypeArgumentIntercepted(4),getRuntimeTypeInfo(1),getTypeArgumentByIndex(2),instanceType(1),setRuntimeTypeInfo(2)],type=[impl:A<dynamic>,impl:Function,inst:Closure,inst:JSArray<dynamic>,inst:JSBool,inst:JSExtendableArray<dynamic>,inst:JSFixedArray<dynamic>,inst:JSMutableArray<dynamic>,inst:JSUnmodifiableArray<dynamic>,is:A<A.T>]*/
testA(c, f) => extractTypeArguments<A>(c, f);

/*member: testB:dynamic=[call<B.S,B.U>(0)],static=[Rti._bind(1),Rti._eval(1),_arrayInstanceType(1),_asBoolNullable(1),_asDoubleNullable(1),_asIntNullable(1),_asNumNullable(1),_asObject(1),_asStringNullable(1),_asTop(1),_generalAsCheckImplementation(1),_generalIsTestImplementation(1),_installSpecializedIsTest(1),_instanceType(1),_isBool(1),_isInt(1),_isNum(1),_isObject(1),_isString(1),_isTop(1),checkSubtype(4),extractTypeArguments<B<dynamic,dynamic>>(2),findType(1),getRuntimeTypeArgument(3),getRuntimeTypeArgumentIntercepted(4),getRuntimeTypeInfo(1),getTypeArgumentByIndex(2),instanceType(1),setRuntimeTypeInfo(2)],type=[impl:B<dynamic,dynamic>,impl:Function,inst:Closure,inst:JSArray<dynamic>,inst:JSBool,inst:JSExtendableArray<dynamic>,inst:JSFixedArray<dynamic>,inst:JSMutableArray<dynamic>,inst:JSUnmodifiableArray<dynamic>,is:B<B.S,B.U>]*/
testB(c, f) => extractTypeArguments<B>(c, f);

/*member: main:static=[C.(0),testA(2),testB(2)],type=[inst:JSNull]*/
main() {
  var c = new C();
  testA(c, null);
  testB(c, null);
}
