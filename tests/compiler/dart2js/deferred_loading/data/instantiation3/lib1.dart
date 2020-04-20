// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: getFoo:OutputUnit(1, {b})*/
T getFoo<T>(T v) => v;

typedef dynamic G<T>(T v);

/*member: m:
 OutputUnit(1, {b}),
 constants=[FunctionConstant(getFoo)=OutputUnit(1, {b})]
*/
m(int x, {G<int> f}) {
  f ??= getFoo;
  print(f(x));
}
