// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef num FunctionReturningNum();

test() {
  int i = 1;
  Object o = 1;
  FunctionReturningNum a = /*@ returnType=int* */ () => i;
  FunctionReturningNum b = /*@ returnType=num* */ () => o;
  FunctionReturningNum c = /*@ returnType=int* */ () {
    return i;
  };
  FunctionReturningNum d = /*@ returnType=num* */ () {
    return o;
  };
}

main() {}
