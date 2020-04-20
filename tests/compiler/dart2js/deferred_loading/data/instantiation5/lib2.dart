// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: getFoo:OutputUnit(3, {c})*/
T getFoo<T>(T v) => v;

typedef dynamic G<T>(T v);

/*member: m:
 OutputUnit(3, {c}),
 constants=[FunctionConstant(getFoo)=OutputUnit(3, {c})]
*/
m(int x, {G<int> f}) {
  f ??= getFoo;
  print(f(x));
}
