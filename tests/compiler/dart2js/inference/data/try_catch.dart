// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: returnInt1:[exact=JSUInt31]*/
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {}
  return a;
}

/*element: returnDyn1:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn1() {
  dynamic a = 42;
  try {
    a = 'foo';
  } catch (e) {}
  return a;
}

/*element: returnInt2:[exact=JSUInt31]*/
returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 2;
  }
  return a;
}

/*element: returnDyn2:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn2() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  }
  return a;
}

/*element: returnInt3:[exact=JSUInt31]*/
returnInt3() {
  dynamic a = 42;
  try {
    a = 54;
  } catch (e) {
    a = 'foo';
  } finally {
    a = 4;
  }
  return a;
}

/*element: returnDyn3:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn3() {
  dynamic a = 42;
  try {
    a = 54;
    // ignore: unused_catch_clause
  } on String catch (e) {
    a = 2;
    // ignore: unused_catch_clause
  } on Object catch (e) {
    a = 'foo';
  }
  return a;
}

/*element: returnInt4:[exact=JSUInt31]*/
returnInt4() {
  var a = 42;
  try {
    a = 54;
    // ignore: unused_catch_clause
  } on String catch (e) {
    a = 2;
    // ignore: unused_catch_clause
  } on Object catch (e) {
    a = 32;
  }
  return a;
}

/*element: returnDyn4:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn4() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 'foo';
    } catch (e) {}
  }
  return a;
}

/*element: returnInt5:[exact=JSUInt31]*/
returnInt5() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*element: returnDyn5:Union([exact=JSString], [exact=JSUInt31])*/
returnDyn5() {
  dynamic a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {}
  }
  return a;
}

/*element: returnInt6:[subclass=JSInt]*/
returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  // ignore: dead_code
  return 42;
}

/*element: returnDyn6:[null|subclass=Object]*/
returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}

/*element: returnInt7:[exact=JSUInt31]*/
returnInt7() {
  dynamic a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {}
  return 2;
}

/*element: main:[null]*/
main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
  returnDyn4();
  returnInt5();
  returnDyn5();
  returnInt6();
  returnDyn6();
  returnInt7();
}
