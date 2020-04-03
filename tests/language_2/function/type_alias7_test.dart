// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void funcType([int arg]);

typedef void badFuncType([int arg = 0]); //# 00: compile-time error

typedef void badFuncType({int arg: 0}); //# 02: compile-time error

class A
  extends funcType // //# 01: compile-time error
{}

main() {
  new A();
  badFuncType f; //# 00: continued
  badFuncType f; //# 02: continued
}
