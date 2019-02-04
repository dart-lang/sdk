// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

class SubClass extends Class {
  method() {}
}

/*element: main:
 static=[
  dynamicToEquals(1),
  dynamicToHashCode(1),
  dynamicToNoSuchMethod(1),
  dynamicToNoSuchMethodTearOff(1),
  dynamicToNoSuchMethodWrong(1),
  dynamicToString(1),
  dynamicToStringTearOff(1),
  dynamicToStringWrong(1),
  negativeDynamic(1),
  positiveDynamic(1),
  positiveTyped(1)],
 type=[inst:JSNull]
*/
main() {
  positiveTyped(null);
  positiveDynamic(null);
  negativeDynamic(null);
  dynamicToString(null);
  dynamicToStringWrong(null);
  dynamicToStringTearOff(null);
  dynamicToEquals(null);
  dynamicToHashCode(null);
  dynamicToNoSuchMethod(null);
  dynamicToNoSuchMethodWrong(null);
  dynamicToNoSuchMethodTearOff(null);
}

/*element: positiveTyped:dynamic=[SubClass.method(0)],type=[inst:JSBool,is:SubClass,param:Class]*/
positiveTyped(Class cls) {
  if (cls is SubClass) cls.method();
}

/*element: positiveDynamic:dynamic=[SubClass.method(0)],type=[inst:JSBool,is:SubClass]*/
positiveDynamic(dynamic cls) {
  if (cls is SubClass) cls.method();
}

/*element: negativeDynamic:dynamic=[SubClass.method(0)],type=[inst:JSBool,is:SubClass]*/
negativeDynamic(dynamic cls) {
  if (cls is! SubClass) return;
  cls.method();
}

/*element: dynamicToString:dynamic=[Object.toString(0)]*/
dynamicToString(dynamic cls) {
  cls.toString();
}

/*element: dynamicToStringWrong:dynamic=[call(1),toString(1)],type=[inst:JSNull]*/
dynamicToStringWrong(dynamic cls) {
  cls.toString(null);
}

/*element: dynamicToStringTearOff:dynamic=[Object.toString]*/
dynamicToStringTearOff(dynamic cls) {
  cls.toString;
}

/*element: dynamicToEquals:dynamic=[Object.==],type=[inst:JSNull]*/
dynamicToEquals(dynamic cls) {
  cls == null;
}

/*element: dynamicToHashCode:dynamic=[Object.hashCode]*/
dynamicToHashCode(dynamic cls) {
  cls.hashCode;
}

/*element: dynamicToNoSuchMethod:dynamic=[Object.noSuchMethod(1)],type=[inst:JSNull]*/
dynamicToNoSuchMethod(dynamic cls) {
  cls.noSuchMethod(null);
}

/*element: dynamicToNoSuchMethodWrong:dynamic=[call(0),noSuchMethod(0)]*/
dynamicToNoSuchMethodWrong(dynamic cls) {
  cls.noSuchMethod();
}

/*element: dynamicToNoSuchMethodTearOff:dynamic=[Object.noSuchMethod]*/
dynamicToNoSuchMethodTearOff(dynamic cls) {
  cls.noSuchMethod;
}
