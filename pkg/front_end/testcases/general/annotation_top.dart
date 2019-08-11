// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@a
@A(1)
library test;

const Object a = const Object();

class A {
  const A(int value);
}

@a
@A(2)
class C {}

@a
@A(2)
typedef void F1();

@a
@A(3)
typedef F2 = void Function();

@a
@A(3)
int f1, f2;

@a
@A(4)
void main() {}
