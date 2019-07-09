// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

class SubClass extends Class {
  method() {}
}

/*member: main:
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

/*member: positiveTyped:dynamic=[SubClass.method(0)],type=[inst:JSBool,is:SubClass,param:Class]*/
positiveTyped(Class cls) {
  if (cls is SubClass) cls.method();
}

/*member: positiveDynamic:dynamic=[SubClass.method(0)],type=[inst:JSBool,is:SubClass]*/
positiveDynamic(dynamic cls) {
  if (cls is SubClass) cls.method();
}

/*member: negativeDynamic:dynamic=[SubClass.method(0)],type=[inst:JSBool,is:SubClass]*/
negativeDynamic(dynamic cls) {
  if (cls is! SubClass) return;
  cls.method();
}

/*member: dynamicToString:dynamic=[Object.toString(0)]*/
dynamicToString(dynamic cls) {
  cls.toString();
}

/*member: dynamicToStringWrong:dynamic=[call(1),toString(1)],type=[inst:JSNull]*/
dynamicToStringWrong(dynamic cls) {
  cls.toString(null);
}

/*member: dynamicToStringTearOff:dynamic=[Object.toString]*/
dynamicToStringTearOff(dynamic cls) {
  cls.toString;
}

/*member: dynamicToEquals:dynamic=[Object.==],type=[inst:JSNull]*/
dynamicToEquals(dynamic cls) {
  cls == null;
}

/*member: dynamicToHashCode:dynamic=[Object.hashCode]*/
dynamicToHashCode(dynamic cls) {
  cls.hashCode;
}

/*member: dynamicToNoSuchMethod:dynamic=[Object.noSuchMethod(1)],type=[inst:JSNull]*/
dynamicToNoSuchMethod(dynamic cls) {
  cls.noSuchMethod(null);
}

/*member: dynamicToNoSuchMethodWrong:dynamic=[call(0),noSuchMethod(0)]*/
dynamicToNoSuchMethodWrong(dynamic cls) {
  cls.noSuchMethod();
}

/*member: dynamicToNoSuchMethodTearOff:dynamic=[Object.noSuchMethod]*/
dynamicToNoSuchMethodTearOff(dynamic cls) {
  cls.noSuchMethod;
}
