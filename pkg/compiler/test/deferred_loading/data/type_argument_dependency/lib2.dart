// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:OutputUnit(1, {c}), type=OutputUnit(1, {c})*/
class A {
  /*member: A.:OutputUnit(1, {c})*/
  A();
}

/*class: B:none, type=OutputUnit(main, {})*/
class B extends A {}

/*member: createA:OutputUnit(1, {c})*/
createA() => new A();
