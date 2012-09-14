// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int x;
  const A.a1() : x = 'foo';
  const A.a2(this.x);
  const A.a3([this.x = 'foo']);
  const A.a4(String this.x);
  const A.a5(String x) : this.x = x;
  const A.a6(int x) : this.x = x;
}

const a1 = const A.a1(); /// 01: compile-time error
const a2 = const A.a2('foo'); /// 02: compile-time error
const a3 = const A.a3(); /// 03: compile-time error
const a4 = const A.a4('foo'); /// 04: compile-time error
const a5 = const A.a5('foo'); /// 05: compile-time error
const a6 = const A.a6('foo'); /// 06: compile-time error

var b1 = const A.a1(); /// 07: compile-time error
var b2 = const A.a2('foo'); /// 08: compile-time error
var b3 = const A.a3(); /// 09: compile-time error
var b4 = const A.a4('foo'); /// 10: compile-time error
var b5 = const A.a5('foo'); /// 11: compile-time error
var b6 = const A.a6('foo'); /// 12: compile-time error

main() {
  print(a1); /// 01: continued
  print(a2); /// 02: continued
  print(a3); /// 03: continued
  print(a4); /// 04: continued
  print(a5); /// 05: continued
  print(a6); /// 06: continued

  print(b1); /// 07: continued
  print(b2); /// 08: continued
  print(b3); /// 09: continued
  print(b4); /// 10: continued
  print(b5); /// 11: continued
  print(b6); /// 12: continued
}
