// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*kernel.class: A:OutputUnit(1, {c})*/
/*strong.class: A:OutputUnit(main, {})*/
/*omit.class: A:OutputUnit(main, {})*/
class A {
  /*element: A.:OutputUnit(1, {c})*/
  A();
}

/*class: B:OutputUnit(main, {})*/
class B extends A {}

/*element: createA:OutputUnit(1, {c})*/
createA() => new A();
