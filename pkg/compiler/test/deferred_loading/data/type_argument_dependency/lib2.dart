// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:
 class_unit=1{c},
 type_unit=1{c}
*/
class A {
  /*member: A.:member_unit=1{c}*/
  A();
}

/*class: B:
 class_unit=none,
 type_unit=main{}
*/
class B extends A {}

/*member: createA:member_unit=1{c}*/
createA() => new A();
