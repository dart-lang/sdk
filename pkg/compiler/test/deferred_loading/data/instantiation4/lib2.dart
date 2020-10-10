// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: getFoo:member_unit=3{c}*/
T getFoo<T, S>(T v, S w) => v;

typedef dynamic G<T, S>(T v, S w);

/*member: m:
 constants=[InstantiationConstant([int*, int*],FunctionConstant(getFoo))=3{c}],
 member_unit=3{c}
*/
m(int x, int y, {G<int, int> f}) {
  f ??= getFoo;
  print(f(x, y));
}
