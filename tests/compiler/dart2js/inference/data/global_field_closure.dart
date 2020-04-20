// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: method1:[exact=JSUInt31]*/
method1() {
  return 42;
}

/*member: method2:[exact=JSUInt31]*/
// Called only via [foo2] with a small integer.
method2(/*[exact=JSUInt31]*/ a) {
  return a;
}

/*member: foo1:[subclass=Closure]*/
var foo1 = method1;

/*member: foo2:[subclass=Closure]*/
var foo2 = method2;

/*member: returnInt1:[null|subclass=Object]*/
returnInt1() {
  return foo1();
}

/*member: returnInt2:[null|subclass=Object]*/
returnInt2() {
  return foo2(54);
}

/*member: main:[null]*/
main() {
  returnInt1();
  returnInt2();
}
