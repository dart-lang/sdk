// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: Class1a.:static=[Object.(0)]*/
class Class1a<T> {
  /*element: Class1a.==:
   dynamic=[this:Class1a.runtimeType,Object.runtimeType,Type.==],
   runtimeType=[equals:Class1a<Class1a.T>/Object]
  */
  bool operator ==(other) {
    return runtimeType == other.runtimeType;
  }
}

/*element: Class1b.:static=[Class1a.(0)]*/
class Class1b<T> extends Class1a<T> {
  /*element: Class1b.==:
   dynamic=[this:Class1b.runtimeType,Object.runtimeType,Type.==],
   runtimeType=[equals:Object/Class1b<Class1b.T>]
  */
  bool operator ==(other) {
    return other.runtimeType == runtimeType;
  }
}

/*element: Class1c.:static=[Object.(0)]*/
class Class1c<T> implements Class1a<T> {
  /*element: Class1c.==:
   dynamic=[this:Class1c.runtimeType,Object.==,Object.runtimeType,Type.==],
   runtimeType=[equals:Class1c<Class1c.T>/Object],
   type=[inst:JSNull]
  */
  bool operator ==(other) {
    return runtimeType == other?.runtimeType;
  }
}

/*element: Class1d.:static=[Object.(0)]*/
class Class1d<T> implements Class1a<T> {
  /*element: Class1d.==:
   dynamic=[this:Class1d.runtimeType,Object.==,Object.runtimeType,Type.==],
   runtimeType=[equals:Object/Class1d<Class1d.T>],
   type=[inst:JSNull]
  */
  bool operator ==(other) {
    return other?.runtimeType == runtimeType;
  }
}

/*element: Class2.:static=[Object.(0)]*/
class Class2<T> {}

/*element: Class3.:static=[Object.(0)]*/
class Class3 {
  /*element: Class3.field:type=[inst:JSNull]*/
  var field;
}

/*element: Class4.:static=[Object.(0)]*/
class Class4 {}

/*element: toString1:
 dynamic=[Class2.runtimeType,toString(0)],
 runtimeType=[string:Class2<int>],
 static=[
  S(1),
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSString,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
toString1(Class2<int> c) => '${c.runtimeType}';

/*element: toString2:
 dynamic=[Class2.==,Class2.runtimeType,toString(0)],
 runtimeType=[string:Class2<int>],
 static=[
  S(1),
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSString,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
toString2(Class2<int> c) => '${c?.runtimeType}';

/*element: toString3:
 dynamic=[Class2.runtimeType,Type.toString(0)],
 runtimeType=[string:Class2<int>],
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
toString3(Class2<int> c) => c.runtimeType.toString();

/*element: toString4:
 dynamic=[Class2.runtimeType,Type.==,Type.toString(0)],
 runtimeType=[string:Class2<int>],
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
toString4(Class2<int> c) => c.runtimeType?.toString();

/*element: toString5:
 dynamic=[Class2.==,Class2.runtimeType,Type.==,Type.toString(0)],
 runtimeType=[string:Class2<int>],
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
toString5(Class2<int> c) => c?.runtimeType?.toString();

/*element: toString6:
 dynamic=[Class2.==,Class2.runtimeType,Type.toString(0)],
 runtimeType=[string:Class2<int>],
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
toString6(Class2<int> c) => c?.runtimeType.toString();

/*element: unknown:
 dynamic=[Class2.runtimeType],
 runtimeType=[unknown:Class2<int>],
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class2<int>]
*/
unknown(Class2<int> c) => c.runtimeType;

/*element: equals1:
 dynamic=[Class1a.==,Class1a.runtimeType,Class1d.==,Class1d.runtimeType,Type.==],
 runtimeType=[equals:Class1a<int>/Class1d<int>],
 static=[
  checkSubtype(4),
  getRuntimeTypeArgument(3),
  getRuntimeTypeArgumentIntercepted(4),
  getRuntimeTypeInfo(1),
  getTypeArgumentByIndex(2),
  setRuntimeTypeInfo(2)],
 type=[
  inst:JSArray<dynamic>,
  inst:JSBool,
  inst:JSExtendableArray<dynamic>,
  inst:JSFixedArray<dynamic>,
  inst:JSMutableArray<dynamic>,
  inst:JSNull,
  inst:JSUnmodifiableArray<dynamic>,
  param:Class1a<int>,
  param:Class1d<int>]
*/
equals1(Class1a<int> a, Class1d<int> b) => a?.runtimeType == b?.runtimeType;

/*element: almostEquals1:
 dynamic=[Class3.runtimeType,Type.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals1(Class3 a) => a.runtimeType == null;

/*element: almostEquals2:
 dynamic=[Class3.==,Class3.runtimeType,Type.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals2(Class3 a) => a?.runtimeType == null;

/*element: almostEquals3:
 dynamic=[Class3.runtimeType,Null.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals3(Class3 a) => null == a.runtimeType;

/*element: almostEquals4:
 dynamic=[Class3.==,Class3.runtimeType,Null.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals4(Class3 a) => null == a?.runtimeType;

/*element: almostEquals5:
 dynamic=[Class3.field,Class3.runtimeType,Type.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,param:Class3]
*/
almostEquals5(Class3 a) => a.runtimeType == a.field;

/*element: almostEquals6:
 dynamic=[Class3.==,Class3.field,Class3.runtimeType,Type.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals6(Class3 a) => a?.runtimeType == a.field;

/*element: almostEquals7:
 dynamic=[Class3.==,Class3.field,Class3.runtimeType,Type.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals7(Class3 a) => a.runtimeType == a?.field;

/*element: almostEquals8:
 dynamic=[Class3.==,Class3.field,Class3.runtimeType,Type.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals8(Class3 a) => a?.runtimeType == a?.field;

/*element: almostEquals9:
 dynamic=[Class3.field,Class3.runtimeType,Object.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,param:Class3]
*/
almostEquals9(Class3 a) => a.field == a.runtimeType;

/*element: almostEquals10:
 dynamic=[Class3.==,Class3.field,Class3.runtimeType,Object.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals10(Class3 a) => a?.field == a.runtimeType;

/*element: almostEquals11:
 dynamic=[Class3.==,Class3.field,Class3.runtimeType,Object.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals11(Class3 a) => a.field == a?.runtimeType;

/*element: almostEquals12:
 dynamic=[Class3.==,Class3.field,Class3.runtimeType,Object.==],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostEquals12(Class3 a) => a?.field == a?.runtimeType;

/*element: almostToString1:
 dynamic=[Class3.runtimeType,Type.toString],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,param:Class3]
*/
almostToString1(Class3 a) => a.runtimeType.toString;

/*element: almostToString2:
 dynamic=[Class3.==,Class3.runtimeType,Type.==,Type.toString],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostToString2(Class3 a) => a?.runtimeType?.toString;

/*element: almostToString3:
 dynamic=[Class3.runtimeType,Type.noSuchMethod(1)],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostToString3(Class3 a) => a.runtimeType.noSuchMethod(null);

/*element: almostToString4:
 dynamic=[Class3.==,Class3.runtimeType,Type.noSuchMethod(1)],
 runtimeType=[unknown:Class3],
 type=[inst:JSBool,inst:JSNull,param:Class3]
*/
almostToString4(Class3 a) => a?.runtimeType.noSuchMethod(null);

/*element: notEquals1:
 dynamic=[Class3.runtimeType,Class4.runtimeType,Type.==],
 runtimeType=[equals:Class3/Class4],
 type=[inst:JSBool,param:Class3,param:Class4]
*/
notEquals1(Class3 a, Class4 b) => a.runtimeType != b.runtimeType;

/*element: notEquals2:
 dynamic=[Class3.==,Class3.runtimeType,Class4.runtimeType,Type.==],
 runtimeType=[equals:Class3/Class4],
 type=[inst:JSBool,inst:JSNull,param:Class3,param:Class4]
*/
notEquals2(Class3 a, Class4 b) => a?.runtimeType != b.runtimeType;

/*element: notEquals3:
 dynamic=[Class3.runtimeType,Class4.==,Class4.runtimeType,Type.==],
 runtimeType=[equals:Class3/Class4],
 type=[inst:JSBool,inst:JSNull,param:Class3,param:Class4]
*/
notEquals3(Class3 a, Class4 b) => a.runtimeType != b?.runtimeType;

/*element: notEquals4:
 dynamic=[Class3.==,Class3.runtimeType,Class4.==,Class4.runtimeType,Type.==],
 runtimeType=[equals:Class3/Class4],
 type=[inst:JSBool,inst:JSNull,param:Class3,param:Class4]
*/
notEquals4(Class3 a, Class4 b) => a?.runtimeType != b?.runtimeType;

/*element: main:
 dynamic=[exact:Class1a.==],
 static=[
  Class1a.(0),
  Class1b.(0),
  Class1c.(0),
  Class1d.(0),
  Class2.(0),
  Class3.(0),
  Class4.(0),
  almostEquals1(1),
  almostEquals10(1),
  almostEquals11(1),
  almostEquals12(1),
  almostEquals2(1),
  almostEquals3(1),
  almostEquals4(1),
  almostEquals5(1),
  almostEquals6(1),
  almostEquals7(1),
  almostEquals8(1),
  almostEquals9(1),
  almostToString1(1),
  almostToString2(1),
  almostToString3(1),
  almostToString4(1),
  assertIsSubtype(5),
  equals1(2),
  notEquals1(2),
  notEquals2(2),
  notEquals3(2),
  notEquals4(2),
  print(1),
  throwTypeError(1),
  toString1(1),
  toString2(1),
  toString3(1),
  toString4(1),
  toString5(1),
  toString6(1),
  unknown(1)]
*/
main() {
  Class1a<int> c1a = new Class1a<int>();
  Class1b<int> c1b = new Class1b<int>();
  Class1c<int> c1c = new Class1c<int>();
  Class1d<int> c1d = new Class1d<int>();
  Class2<int> c2 = new Class2<int>();
  Class3 c3 = new Class3();
  Class4 c4 = new Class4();
  print(c1a == c1b);
  print(c1a == c1c);
  print(c1a == c1d);
  print(c1a == c2);
  toString1(c2);
  toString2(c2);
  toString3(c2);
  toString4(c2);
  toString5(c2);
  toString6(c2);
  unknown(c2);
  equals1(c1a, c1d);
  almostEquals1(c3);
  almostEquals2(c3);
  almostEquals3(c3);
  almostEquals4(c3);
  almostEquals5(c3);
  almostEquals6(c3);
  almostEquals7(c3);
  almostEquals8(c3);
  almostEquals9(c3);
  almostEquals10(c3);
  almostEquals11(c3);
  almostEquals12(c3);
  almostToString1(c3);
  almostToString2(c3);
  almostToString3(c3);
  almostToString4(c3);
  notEquals1(c3, c4);
  notEquals2(c3, c4);
  notEquals3(c3, c4);
  notEquals4(c3, c4);
}
