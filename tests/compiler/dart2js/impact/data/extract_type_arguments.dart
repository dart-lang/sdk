// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_internal';

class A<T> {}

class B<S, U> {}

/*member: C.:static=[Object.(0)]*/
class C implements A<int>, B<String, bool> {}

/*member: testA:
 dynamic=[call<A.T>(0)],
 static=[
  checkSubtype(4),
  extractTypeArguments<A<dynamic>>(2),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  impl:A<dynamic>,
  impl:Function,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,is:A<A.T>]
*/
testA(c, f) => extractTypeArguments<A>(c, f);

/*member: testB:
 dynamic=[call<B.S,B.U>(0)],
 static=[
  checkSubtype(4),
  extractTypeArguments<B<dynamic,dynamic>>(2),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  impl:B<dynamic,dynamic>,
  impl:Function,
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  is:B<B.S,B.U>]
*/
testB(c, f) => extractTypeArguments<B>(c, f);

/*member: main:static=[C.(0),testA(2),testB(2)],type=[inst:JSNull]*/
main() {
  var c = new C();
  testA(c, null);
  testB(c, null);
}
