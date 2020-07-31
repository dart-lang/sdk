// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library deferred_typedef_lib1;

/*class: C:OutputUnit(1, {lib1})*/
class C {
  /*member: C.a:OutputUnit(1, {lib1})*/
  final a;

  /*member: C.b:OutputUnit(1, {lib1})*/
  final b;

  const C(this.a, this.b);
}

typedef void MyF1();

typedef void MyF2();

/*member: topLevelMethod:OutputUnit(1, {lib1})*/
topLevelMethod() {}

const cA = const C(MyF1, topLevelMethod);

const cB = MyF2;
