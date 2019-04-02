// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: method1:[exact=JSUInt31]*/
method1() {
  return 42;
}

/*element: method2:[exact=JSUInt31]*/
// Called only via [foo2] with a small integer.
method2(/*[exact=JSUInt31]*/ a) {
  return a;
}

/*strong.element: foo1:[null|subclass=Closure]*/
/*omit.element: foo1:[null|subclass=Closure]*/
/*strongConst.element: foo1:[subclass=Closure]*/
/*omitConst.element: foo1:[subclass=Closure]*/
var foo1 = method1;

/*strong.element: foo2:[null|subclass=Closure]*/
/*omit.element: foo2:[null|subclass=Closure]*/
/*strongConst.element: foo2:[subclass=Closure]*/
/*omitConst.element: foo2:[subclass=Closure]*/
var foo2 = method2;

/*element: returnInt1:[null|subclass=Object]*/
returnInt1() {
  return foo1();
}

/*element: returnInt2:[null|subclass=Object]*/
returnInt2() {
  return foo2(54);
}

/*element: main:[null]*/
main() {
  returnInt1();
  returnInt2();
}
