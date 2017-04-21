// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int x;
  const A.a1() : x = 'foo'; //# 01: continued
  const A.a2(this.x);
  const A.a3([this.x = 'foo']); //# 03: continued
  const A.a4(String this.x); //# 04: continued
  const A.a5(String x) : this.x = x; //# 05: continued
  const A.a6(int x) : this.x = x;
}

const a1 = const A.a1(); //# 01: static type warning, checked mode compile-time error
const a2 = const A.a2('foo'); //# 02: static type warning, checked mode compile-time error
const a3 = const A.a3(); //# 03: static type warning, checked mode compile-time error
const a4 = const A.a4('foo'); //# 04: static type warning, checked mode compile-time error
const a5 = const A.a5('foo'); //# 05: static type warning, checked mode compile-time error
const a6 = const A.a6('foo'); //# 06: static type warning, checked mode compile-time error

main() {
  print(a1); //# 01: continued
  print(a2); //# 02: continued
  print(a3); //# 03: continued
  print(a4); //# 04: continued
  print(a5); //# 05: continued
  print(a6); //# 06: continued
}
