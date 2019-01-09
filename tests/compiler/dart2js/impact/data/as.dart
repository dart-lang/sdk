// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:static=[explicitAs(1),implicitAs(1),promoted(1)],type=[inst:JSNull]*/
main() {
  explicitAs(null);
  implicitAs(null);
  promoted(null);
}

/*element: explicitAs:dynamic=[String.length],type=[inst:JSBool,param:String]*/
explicitAs(String i) {
  i.length;
  // ignore: unnecessary_cast
  return i as String;
}

/*element: implicitAs:dynamic=[String.length],type=[inst:JSBool,param:String]*/
String implicitAs(String i) {
  dynamic j = i;
  i.length;
  j.length;
  return j;
}

/*element: promoted:dynamic=[String.length],type=[inst:JSBool,inst:JSNull,is:String]*/
String promoted(dynamic i) {
  if (i is! String) return null;
  i.length;
  return i;
}
